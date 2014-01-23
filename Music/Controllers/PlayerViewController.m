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

@property (strong, nonatomic) UIView *nowPlayingView;
@property (strong, nonatomic) NowPlayingViewController *nowPlaying;

@property (strong, nonatomic) UIView *dummyNowPlayingView;
@property (strong, nonatomic) NowPlayingViewController *dummyNowPlaying;

@end

@implementation PlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Player"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"music"]];
        
        NowPlayingViewController *nowPlaying = [[NowPlayingViewController alloc] initWithNibName:@"NowPlayingView" bundle:nil];
        [self setNowPlaying:nowPlaying];

        NowPlayingViewController *dummy = [[NowPlayingViewController alloc] initWithNibName:@"NowPlayingView" bundle:nil];
        [self setDummyNowPlaying:dummy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncView) name:@"PlayerUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songDidFailToPlay) name:@"SongFailed" object:nil];
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNowPlayingView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)]];
    [[self nowPlayingView] addSubview:[[self nowPlaying] view]];
    [[self view] addSubview:[self nowPlayingView]];
    
    [self setDummyNowPlayingView:[[UIView alloc] initWithFrame:CGRectMake(320, 0, 320, 400)]];
    [[self dummyNowPlayingView] addSubview:[[self dummyNowPlaying] view]];
    [[self view] addSubview:[self dummyNowPlayingView]];

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
        
    Song *song = [Song currentSongInPlaylist];
    
    [[self nowPlaying] setSong:song];
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

#pragma mark - Animations

- (void)animateNowPlayingToOriginal
{
    [UIView animateWithDuration:ANIMATION_SPEED animations:^{
        [[self nowPlayingView] setFrame:CGRectMake(0, 0, 320, 400)];
        if ([[self dummyNowPlayingView] frame].origin.x < 0)
            [[self dummyNowPlayingView] setFrame:CGRectMake(-320, 0, 320, 400)];
        else
            [[self dummyNowPlayingView] setFrame:CGRectMake(320, 0, 320, 400)];
    } completion:nil];
}

- (void)animateNowPlayingToNext
{
    [[self dummyNowPlaying] setSong:[[[User currentUser] playlist] objectAtIndex:[[User currentUser] currentPlaylistIndex] + 1]];
    [UIView animateWithDuration:ANIMATION_SPEED animations:^{
        [[self nowPlayingView] setFrame:CGRectMake(-320, 0, 320, 400)];
        [[self dummyNowPlayingView] setFrame:CGRectMake(0, 0, 320, 400)];
    } completion:^(BOOL finished) {
        [self swapDummyWithNowPlaying];
        [self playNextSong:nil];
    }];
}

- (void)animateNowPlayingToPrevious
{
    [[self dummyNowPlaying] setSong:[[[User currentUser] playlist] objectAtIndex:[[User currentUser] currentPlaylistIndex] - 1]];
    [UIView animateWithDuration:ANIMATION_SPEED animations:^{
        [[self nowPlayingView] setFrame:CGRectMake(320, 0, 320, 400)];
        [[self dummyNowPlayingView] setFrame:CGRectMake(0, 0, 320, 400)];
    } completion:^(BOOL finished) {
        [self swapDummyWithNowPlaying];
        [self playPreviousSong:nil];
    }];
}

#pragma mark - Gestures

- (void)pan :(UIPanGestureRecognizer *)gesture
{
    CGPoint origin = [[self nowPlayingView] frame].origin;
    CGSize size = [[self nowPlayingView] frame].size;
    CGPoint point = [gesture translationInView:[self view]];

    if ([gesture state] == UIGestureRecognizerStateBegan)
        [gesture setTranslation:origin inView:[self view]];
    else if([gesture state] == UIGestureRecognizerStateChanged)
    {
        if (point.x > 20 && ![[Player shared] isCurrentIndexFirst])
        {
            [[self nowPlayingView] setFrame:CGRectMake(point.x, origin.y, size.width, size.height)];
            [[self dummyNowPlayingView] setFrame:CGRectMake(point.x - 340, origin.y, size.width, size.height)];
            if ([[self dummyNowPlaying] song] == nil)
                [[self dummyNowPlaying] setSong:[[[User currentUser] playlist] objectAtIndex:[[User currentUser] currentPlaylistIndex] - 1]];
        }
        else if(point.x < -20 && ![[Player shared] isCurrentIndexLast])
        {
            [[self nowPlayingView] setFrame:CGRectMake(point.x, origin.y, size.width, size.height)];
            [[self dummyNowPlayingView] setFrame:CGRectMake(point.x + 340, origin.y, size.width, size.height)];
            if ([[self dummyNowPlaying] song] == nil)
                [[self dummyNowPlaying] setSong:[[[User currentUser] playlist] objectAtIndex:[[User currentUser] currentPlaylistIndex] + 1]];
        }
        else
        {
            if ([[self dummyNowPlaying] song] != nil)
                [[self dummyNowPlaying] setSong:nil];
           [[self nowPlayingView] setFrame:CGRectMake(point.x, origin.y, size.width, size.height)];
        }
        
    }
    else if([gesture state] == UIGestureRecognizerStateEnded)
    {
        if (point.x > 100 && ![[Player shared] isCurrentIndexFirst])
            [self animateNowPlayingToPrevious];
        else if(point.x < -100 && ![[Player shared] isCurrentIndexLast])
            [self animateNowPlayingToNext];
        else
            [self animateNowPlayingToOriginal];
    }
    else if([gesture state] == UIGestureRecognizerStateFailed || [gesture state] == UIGestureRecognizerStateCancelled)
        [self animateNowPlayingToOriginal];
}

- (void)swapDummyWithNowPlaying
{
    NowPlayingViewController *tempNPVC = [self dummyNowPlaying];
    [self setDummyNowPlaying: [self nowPlaying]];
    [self setNowPlaying:tempNPVC];
    
    UIView *tempNP = [self dummyNowPlayingView];
    [self setDummyNowPlayingView:[self nowPlayingView]];
    [self setNowPlayingView:tempNP];
    
    [self addGestures];
}

- (void)addGestures
{
    [[[self nowPlayingView] gestureRecognizers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[self nowPlayingView] removeGestureRecognizer:obj];
    }];
    [[[self dummyNowPlayingView] gestureRecognizers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[self dummyNowPlayingView] removeGestureRecognizer:obj];
    }];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause:)];
    [doubleTap setNumberOfTapsRequired:2];
    [[self nowPlayingView] addGestureRecognizer:doubleTap];

    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [[self nowPlayingView] addGestureRecognizer:pan];
}

#pragma mark - Others

- (void)songDidFailToPlay
{
    [[[UIAlertView alloc] initWithTitle:@"Failed to play this song" message:@"Please try again later." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    
    [[Player shared] setCurrentStatus:STOPPED];
    [self syncView];
    
    [[Player shared] loadNextSong];
    [[Player shared] play];
}

@end
