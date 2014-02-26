//
//  PlayerViewController.m
//  Music
//
//  Created by Tushar Soni on 12/10/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlaylistViewController.h"
#import "EmptyPlaylistViewController.h"
#import "Player.h"
#import "Playlist.h"
#import "AlbumArtManager.h"
#import "FXBlurView.h"
#import "NowPlayingViewController.h"
#import "Analytics.h"

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UISlider *sliderSeeker;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;
@property (weak, nonatomic) IBOutlet UIButton *buttonPrevious;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (weak, nonatomic) IBOutlet UIButton *buttonRepeat;
@property (weak, nonatomic) IBOutlet UIView *viewForNowPlaying;

@property (strong, nonatomic) UIPageViewController *nowPlayingPageController;

@end

@implementation PlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Player"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"music"]];
        
        [self setNowPlayingPageController:[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil]];
        [[self nowPlayingPageController] setDataSource:self];
        [[self nowPlayingPageController] setDelegate:self];
        
        [self addChildViewController:[self nowPlayingPageController]];

        [[NSNotificationCenter defaultCenter]       addObserver:self
                                                    selector:@selector(syncNowPlayingViewWithPageDirection:ShouldAnimate:)
                                                    name:@"applicationDidBecomeActive"
                                                    object:nil];
        
        [[NSNotificationCenter defaultCenter]       addObserver:self
                                                    selector:@selector(syncNowPlayingViewWithPageDirection:ShouldAnimate:)
                                                    name:@"SongFinished" object:nil];

        [[NSNotificationCenter defaultCenter]       addObserver:self
                                                    selector:@selector(syncView)
                                                    name:@"PlayerUpdated"
                                                    object:nil];

        [[NSNotificationCenter defaultCenter]       addObserver:self
                                                    selector:@selector(songDidFailToPlay)
                                                    name:@"SongFailed"
                                                    object:nil];
    }
    return self;
}

#pragma mark - View

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongFinished" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PlayerUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongFailed" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[[self nowPlayingPageController] view] setFrame:[[self viewForNowPlaying] frame]];
    [[self view] addSubview:[[self nowPlayingPageController] view]];
    [self addGestures];
    [[self buttonRepeat] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [[self sliderSeeker] setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self showEmptyPlaylistViewIfNecessary])
    {
        [self syncNowPlayingViewWithPageDirection:UIPageViewControllerNavigationDirectionForward
                                    ShouldAnimate:NO];
        [self syncView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Player"];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)showEmptyPlaylistViewIfNecessary
{
    if ([[Playlist shared] count] == 0)
    {
        EmptyPlaylistViewController *empty = [[EmptyPlaylistViewController alloc] initWithNibName:nil bundle:nil];
        UINavigationController *navForEmpty = [[UINavigationController alloc] initWithRootViewController:empty];

        NSMutableArray *viewControllers = [[[self tabBarController] viewControllers] mutableCopy];
        [viewControllers replaceObjectAtIndex:0 withObject:navForEmpty];
        [[self tabBarController] setViewControllers:viewControllers];
        
        return YES;
    }
    return NO;
}

- (void)syncNowPlayingViewWithPageDirection: (UIPageViewControllerNavigationDirection) direction ShouldAnimate: (BOOL)animate
{
    if (direction != UIPageViewControllerNavigationDirectionForward && direction!= UIPageViewControllerNavigationDirectionReverse)
    {
        direction = UIPageViewControllerNavigationDirectionForward;
        animate = NO;
    }
    
    [[self nowPlayingPageController] setViewControllers:[NSArray arrayWithObject:[[NowPlayingViewController alloc] initWithSong:[[Playlist shared] currentSong]]] direction:direction animated:animate completion:nil];
}

- (void)syncView
{
    [[self labelTimeLeft] setText:[[Player shared] timeLeftAsString]];
    [[self sliderSeeker] setValue:[[Player shared] getPercentCompleted] animated:YES];
    [[self buttonNext] setEnabled:![[Playlist shared] isCurrentSongLast]];
    [[self buttonPrevious] setEnabled:![[Playlist shared] isCurrentSongFirst]];
    [[self buttonRepeat] setImage:[UIImage imageNamed:([[Player shared] isRepeatOn]) ? @"repeat" : @"norepeat"] forState:UIControlStateNormal];
    
    switch ([[Player shared] currentStatus])
    {
        case PAUSED:
            [[self buttonPlayPause] setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [[self buttonPlayPause] setEnabled:YES];
            break;
        case NOT_STARTED:
            [[self buttonPlayPause] setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [[self buttonPlayPause] setEnabled:YES];
            break;
        case PLAYING:
            [[self buttonPlayPause] setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            [[self buttonPlayPause] setEnabled:YES];
            break;
        case LOADING:
            [[self buttonPlayPause] setEnabled:NO];
            break;
        case FINISHED:
            [[self buttonPlayPause] setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [[self buttonPlayPause] setEnabled:YES];
            break;
    }
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(NowPlayingViewController *)viewController
{
    Song *song = ([[Player shared] isOfflineModeOn]) ? [[Playlist shared] localSongAfter:[viewController song]] : [[Playlist shared] songAfter:[viewController song]];
    if (song == nil)
        return nil;
    
    return [[NowPlayingViewController alloc] initWithSong:song];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(NowPlayingViewController *)viewController
{
    Song *song = ([[Player shared] isOfflineModeOn]) ? [[Playlist shared] localSongBefore:[viewController song]] : [[Playlist shared] songBefore:[viewController song]];
    if (song == nil)
        return nil;

    return [[NowPlayingViewController alloc] initWithSong:song];
}

#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        [[Player shared] loadSong:[[[pageViewController viewControllers] firstObject] song] ShouldPlay:isPlayerPlaying];
        [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Swipe" forKey:@"How"]];
    }
}

#pragma mark - Actions

- (IBAction)togglePlayPause:(UIButton *)sender
{
    [[Player shared] togglePlayPause];
}

- (IBAction)playNextSong:(UIButton *)sender
{
    [[Player shared] loadSong:nextSongAuto ShouldPlay:isPlayerPlaying];
    [self syncNowPlayingViewWithPageDirection:UIPageViewControllerNavigationDirectionForward
                                ShouldAnimate:YES];
    [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Player Control" forKey:@"How"]];
}

- (IBAction)playPreviousSong:(UIButton *)sender
{
    [[Player shared] loadSong:previousSongInPlaylist ShouldPlay:isPlayerPlaying];
    [self syncNowPlayingViewWithPageDirection:UIPageViewControllerNavigationDirectionReverse
                                ShouldAnimate:YES];
    [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Player Control" forKey:@"How"]];
}

- (IBAction)seekerTouched:(UISlider *)sender
{
    if (isPlayerPlaying)
        [[Player shared] togglePlayPause];
}

- (IBAction)seekerReleased:(UISlider *)sender
{
    [[Player shared] seekToPercent:[sender value]];
}

- (IBAction)showPlaylist:(UIButton *)sender
{
    PlaylistViewController *playlistView = [[PlaylistViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navForPlaylist = [[UINavigationController alloc] initWithRootViewController:playlistView];
    
    [[self tabBarController] setModalPresentationStyle:UIModalPresentationNone];
    [[self tabBarController] presentViewController:navForPlaylist animated:YES completion:nil];
}

- (IBAction)toggleRepeat:(UIButton *)sender
{
    [[Player shared] setIsRepeatOn:![[Player shared] isRepeatOn]];
    [self syncView];
}

#pragma mark - Others

- (void)addGestures
{
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause:)];
    [doubleTap setNumberOfTapsRequired:2];
    [[[self nowPlayingPageController] view] addGestureRecognizer:doubleTap];
}

- (void)songDidFailToPlay
{
    [[[UIAlertView alloc] initWithTitle:@"Failed to play this song" message:@"Please try again later." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    
    [[Player shared] setCurrentStatus:NOT_STARTED];
    [self syncView];
    
    [[Player shared] loadSong:nextSongAuto ShouldPlay:YES];
}

@end
