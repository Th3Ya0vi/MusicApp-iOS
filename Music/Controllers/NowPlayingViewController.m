//
//  NowPlayingViewController.m
//  Music
//
//  Created by Tushar Soni on 1/23/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "NowPlayingViewController.h"
#import "AlbumArtManager.h"
#import "FXBlurView.h"
#import "User.h"
#import "Playlist.h"

@interface NowPlayingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageMain;

@end

@implementation NowPlayingViewController

- (id)initWithSong: (Song *)song
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        [self setSong:song];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self resetView];
    if ([self song])
        [self syncView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addBlackMask];
}

- (void)resetView
{
    [[self labelTitle] setText:@""];
    [[self labelSubtitle] setText:@""];
    [[self imageMain] setImage:[UIImage imageNamed:@"DefaultAlbumArt"]];
    [[self imageBackground] setImage:[UIImage imageNamed:@"DefaultAlbumArtDark"]];
}

- (void)addBlackMask
{
    UIView *blackmask = [[UIView alloc] initWithFrame:[[self imageBackground] frame]];
    [blackmask setBackgroundColor:[UIColor blackColor]];
    [blackmask setAlpha:0.15];
    [[self imageBackground] addSubview:blackmask];
}

- (void)syncView
{
    [[self labelTitle] setText:[[self song] name]];
    [[self labelSubtitle] setText:[[[self song] album] name]];
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:[[self song] album] Size:BIG From:@"NowPlaying" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
        if (didSucceed)
        {
            [[self imageMain] setImage:image];
            [[self imageBackground] setImage:[image blurredImageWithRadius:50 iterations:2 tintColor:[UIColor clearColor]]];
        }
    }];
}

@end
