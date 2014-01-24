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

@interface NowPlayingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageMain;

@property (strong, nonatomic) Song *song;

@end

@implementation NowPlayingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setSongIndexInPlaylist:0];
        [self setSong:nil];
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

- (void)setSongIndexInPlaylist:(NSUInteger)songIndexInPlaylist
{
    _songIndexInPlaylist = songIndexInPlaylist;
    if ([[[User currentUser] playlist] count] == 0)
        return;
    [self setSong:[[[User currentUser] playlist] objectAtIndex:[self songIndexInPlaylist]]];
}

- (void)resetView
{
    [[self labelTitle] setText:@""];
    [[self labelSubtitle] setText:@""];
    [[self imageMain] setImage:[UIImage imageNamed:@"DefaultAlbumArt"]];
    [[self imageBackground] setImage:[UIImage imageNamed:@"DefaultAlbumArtDark"]];
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
