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
#import "AlbumArtManager.h"
#import "FXBlurView.h"
#import "NowPlayingViewController.h"

#define ANIMATION_SPEED 0.3
#define PAN_THRESHOLD   100

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UISlider *sliderSeeker;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;
@property (weak, nonatomic) IBOutlet UIButton *buttonPrevious;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (weak, nonatomic) IBOutlet UIButton *buttonRepeat;

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
        [self addChildViewController:[self nowPlayingPageController]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncView) name:@"PlayerUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songDidFailToPlay) name:@"SongFailed" object:nil];
    }
    return self;
}

#pragma mark - View

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"PlayerUpdated"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"SongFailed"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNowPlayingPageControllerView];
    [self addGestures];
    [[self buttonRepeat] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self syncView];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)setNowPlayingPageControllerView
{
    [[[self nowPlayingPageController] view] setFrame:CGRectMake(0, 0, 320, 400)];
    [[self nowPlayingPageController] setViewControllers:[NSArray arrayWithObject:[self nowPlayingViewControllerAtIndex:[[User currentUser] currentPlaylistIndex]]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [[self nowPlayingPageController] setDataSource:self];
    [[self nowPlayingPageController] setDelegate:self];
    [[self view] addSubview:[[self nowPlayingPageController] view]];
}

- (void)showEmptyPlaylistView
{
    EmptyPlaylistViewController *empty = [[EmptyPlaylistViewController alloc] initWithNibName:@"EmptyPlaylistView" bundle:nil];
    UINavigationController *navForEmpty = [[UINavigationController alloc] initWithRootViewController:empty];

    NSMutableArray *viewControllers = [[[self tabBarController] viewControllers] mutableCopy];
    [viewControllers replaceObjectAtIndex:0 withObject:navForEmpty];
    [[self tabBarController] setViewControllers:viewControllers];
}

- (void)syncView
{
    if ([[[User currentUser] playlist] count] == 0)
    {
        [self showEmptyPlaylistView];
        return;
    }
    
    if ([[[[self nowPlayingPageController] viewControllers] firstObject] songIndexInPlaylist] != [[User currentUser] currentPlaylistIndex])
    {
        [[self nowPlayingPageController]
         setViewControllers:[NSArray arrayWithObject:[self nowPlayingViewControllerAtIndex:[[User currentUser] currentPlaylistIndex]]]
                                           direction:UIPageViewControllerNavigationDirectionForward
                                            animated:NO
                                          completion:nil];
    }
    
    [[self labelTimeLeft] setText:[[Player shared] timeLeftAsString]];
    [[self sliderSeeker] setValue:[[Player shared] getPercentCompleted] animated:YES];
    [[self buttonNext] setEnabled:![[Player shared] isCurrentIndexLast]];
    [[self buttonPrevious] setEnabled:![[Player shared] isCurrentIndexFirst]];
    [[self buttonRepeat] setImage:[UIImage imageNamed:([[Player shared] isRepeatOn]) ? @"repeat" : @"norepeat"] forState:UIControlStateNormal];
    
    switch ([[Player shared] currentStatus])
    {
        case PAUSED:
            [[self buttonPlayPause] setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [[self buttonPlayPause] setEnabled:YES];
            break;
        case STOPPED:
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
    if ([viewController songIndexInPlaylist] == [[[User currentUser] playlist] count] - 1)
        return nil;
    
    return [self nowPlayingViewControllerAtIndex:[viewController songIndexInPlaylist] + 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(NowPlayingViewController *)viewController
{
    if ([viewController songIndexInPlaylist] == 0)
        return nil;
    
    return [self nowPlayingViewControllerAtIndex:[viewController songIndexInPlaylist] - 1];
}

- (NowPlayingViewController *)nowPlayingViewControllerAtIndex: (NSUInteger) index
{
    NowPlayingViewController *npvc = [[NowPlayingViewController alloc] initWithNibName:@"NowPlayingView" bundle:nil];
    
    [npvc setSongIndexInPlaylist:index];
    
    return npvc;
}

#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed && finished)
    {
        if ([[previousViewControllers firstObject] songIndexInPlaylist] < [[[pageViewController viewControllers] firstObject] songIndexInPlaylist])
            [[Player shared] loadNextSong];
        else
            [[Player shared] loadPreviousSong];
    }
}

#pragma mark - Actions

- (IBAction)togglePlayPause:(UIButton *)sender
{
    [[Player shared] togglePlayPause];
}

- (IBAction)playNextSong:(UIButton *)sender
{
    [[Player shared] loadNextSong];
}

- (IBAction)playPreviousSong:(UIButton *)sender
{
    [[Player shared] loadPreviousSong];
}

- (IBAction)seekerTouched:(UISlider *)sender
{
    if ([[Player shared] currentStatus] == PLAYING)
        [[Player shared] togglePlayPause];
}

- (IBAction)seekerReleased:(UISlider *)sender
{
    [[Player shared] seekToPercent:[sender value]];
}

- (IBAction)showPlaylist:(UIButton *)sender
{
    PlaylistViewController *playlistView = [[PlaylistViewController alloc] initWithNibName:@"PlaylistView" bundle:nil];
    UINavigationController *navForPlaylist = [[UINavigationController alloc] initWithRootViewController:playlistView];
    
    [self presentViewController:navForPlaylist animated:YES completion:nil];
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
    
    [[Player shared] setCurrentStatus:STOPPED];
    [self syncView];
    
    [[Player shared] loadNextSong];
    [[Player shared] play];
}

@end
