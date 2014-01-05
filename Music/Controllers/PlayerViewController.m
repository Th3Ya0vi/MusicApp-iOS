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

#define ANIMATION_SPEED 0.2
#define PAN_THRESHOLD   100

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeLeft;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbumArt;
@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UISlider *sliderSeeker;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;
@property (weak, nonatomic) IBOutlet UIButton *buttonPrevious;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (weak, nonatomic) IBOutlet UIButton *buttonRepeat;

@end

@implementation PlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Player"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"music"]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncView) name:@"PlayerUpdated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumArtImage) name:@"SongChanged" object:nil];
        
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addGestures];
    
    [[self buttonRepeat] setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:[[self imageAlbumArt] bounds]];
    [self imageAlbumArt].layer.masksToBounds = NO;
    [self imageAlbumArt].layer.shadowColor = [UIColor blackColor].CGColor;
    [self imageAlbumArt].layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    [self imageAlbumArt].layer.shadowOpacity = 0.5f;
    [self imageAlbumArt].layer.shadowPath = shadowPath.CGPath;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self syncView];
    [self updateAlbumArtImage];
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
    
    [[self labelTitle] setText:[song name]];
    [[self labelSubtitle] setText:[[song album] name]];
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

- (void)setAlbumArtPositionToOriginal
{
    CGSize size = [[self imageAlbumArt] frame].size;
    
    [UIView animateWithDuration:ANIMATION_SPEED animations:^{
        [[self imageAlbumArt] setFrame:CGRectMake(33, 65, size.width, size.height)];
    } completion:nil];
}

- (void)updateAlbumArtWhichIsNext: (BOOL)next
{
    CGSize size = [[self imageAlbumArt] frame].size;
    CGPoint origin = [[self imageAlbumArt] frame].origin;
    
    [UIView animateWithDuration:ANIMATION_SPEED animations:^
    {
        [[self imageAlbumArt] setFrame:CGRectMake((next) ? -320 : 320, origin.y, size.width, size.height)];
        
        
        
    } completion:^(BOOL finished)
    {
        if (finished)
        {
            [[self imageAlbumArt] setFrame:CGRectMake((next) ? 320 : -320, origin.y, size.width, size.height)];
            
            (next) ? [self playNextSong:nil] : [self playPreviousSong:nil];
        }
    }];

}

#pragma mark - Gestures

- (void)pan: (UIPanGestureRecognizer *)gesture
{
    CGPoint origin = [[self imageAlbumArt] frame].origin;
    CGSize size = [[self imageAlbumArt] frame].size;
    CGPoint point = [gesture translationInView:[self view]];
    
    if ([gesture state] == UIGestureRecognizerStateBegan)
    {
        [gesture setTranslation:origin inView:[self view]];
    }
    else if([gesture state] == UIGestureRecognizerStateChanged)
    {
        [[self imageAlbumArt] setFrame:CGRectMake(point.x, origin.y, size.width, size.height)];
    }
    else if([gesture state] == UIGestureRecognizerStateCancelled || [gesture state] == UIGestureRecognizerStateFailed)
    {
        [self setAlbumArtPositionToOriginal];
    }
    else if([gesture state] == UIGestureRecognizerStateEnded)
    {
        if (point.x <= -PAN_THRESHOLD && ![[Player shared] isCurrentIndexLast])
            [self updateAlbumArtWhichIsNext:YES];
        else if (point.x >= PAN_THRESHOLD && ![[Player shared] isCurrentIndexFirst])
            [self updateAlbumArtWhichIsNext:NO];
        else
            [self setAlbumArtPositionToOriginal];
    }
    
}

- (void)addGestures
{
    UIView *gestureWindow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 272)];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause:)];
    [doubleTap setNumberOfTapsRequired:2];
    [gestureWindow addGestureRecognizer:doubleTap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [gestureWindow addGestureRecognizer:pan];
    
    [[self view] addSubview:gestureWindow];
}

#pragma mark - Others

- (void)updateAlbumArtImage
{
    if ([[[User currentUser] playlist] count] == 0)
        return;
    Song *song = [Song currentSongInPlaylist];
    
    UIImage *existingImage = [[AlbumArtManager shared] existingImageForAlbum:[song album] Size:BIG];
    
    if (existingImage == nil)
    {
        [[self imageAlbumArt] setImage:[UIImage imageNamed:@"DefaultAlbumArt"]];
        [UIView animateWithDuration:ANIMATION_SPEED animations:^{
                [[self imageBackground] setAlpha:0.3];
        }];
        
        [[self labelTitle] setTextColor:[UIColor blackColor]];
        [[self labelSubtitle] setTextColor:[UIColor blackColor]];
    }
    
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:[song album] Size:BIG From:@"Player" CompletionBlock:^(UIImage *image, BOOL didSucceed)
     {
         if (didSucceed == NO)
             [[self imageAlbumArt] setImage:[UIImage imageNamed:@"DefaultAlbumArt"]];
         else
             [[self imageAlbumArt] setImage:image];
         
         [[self labelTitle] setTextColor:[UIColor whiteColor]];
         [[self labelSubtitle] setTextColor:[UIColor whiteColor]];
         
         [[Player shared] setMediaInfo];
         
         [[self imageBackground] setImage:[image blurredImageWithRadius:50 iterations:2 tintColor:[UIColor clearColor]]];

         [UIView animateWithDuration:ANIMATION_SPEED animations:^
          {
              CGPoint origin = [[self imageAlbumArt] frame].origin;
              CGSize size = [[self imageAlbumArt] frame].size;
              
              [[self imageAlbumArt] setFrame:CGRectMake(33, origin.y, size.width, size.height)];
              [[self imageBackground] setAlpha:1.0];
              
          } completion:nil];
     }];
}


@end
