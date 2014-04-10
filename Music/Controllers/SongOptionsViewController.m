//
//  SongOptionsViewController.m
//  Music
//
//  Created by Tushar Soni on 1/25/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "SongOptionsViewController.h"
#import "Player.h"
#import "Playlist.h"
#import "DownloadsManager.h"
#import "Analytics.h"
#import "RNBlurModalView.h"
#import "AlbumArtManager.h"
#import "FXBlurView.h"

@interface SongOptionsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonPlayNow;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlayNext;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddToPlaylist;
@property (weak, nonatomic) IBOutlet UIButton *buttonDownload;

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDownload;
@property (weak, nonatomic) IBOutlet UILabel *labelPlayNow;
@property (weak, nonatomic) IBOutlet UILabel *labelPlayNext;
@property (weak, nonatomic) IBOutlet UILabel *labelAddToPlaylist;

@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;

@end

@implementation SongOptionsViewController

- (id)initWithSong: (Song *)song Origin: (NSString *)origin
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        [self setSong:song];
        [self setOrigin:origin];
        [self setIsBackgroundTransparent:NO];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self syncView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Song Options"];
}

- (void)syncView
{
    [[self labelTitle] setText:[[self song] name]];
    [[self blurView] hideCloseButton:YES];
    
    if ([self isBackgroundTransparent] == NO)
    {
        [[AlbumArtManager shared] fetchAlbumArtForAlbum:[[self song] album] Size:BIG From:@"Song Options" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
            if (didSucceed)
            {
                [[self imageBackground] setImage:[image blurredImageWithRadius:50 iterations:2 tintColor:[UIColor clearColor]]];
            }
        }];
    }
    else
    {
        [[self imageBackground] removeFromSuperview];
    }
    
    if ([[self song] availability] == UNAVAILABLE)
    {
        [self disableButton:[self buttonAddToPlaylist]];
        [self disableButton:[self buttonDownload]];
        [self disableButton:[self buttonPlayNext]];
        [self disableButton:[self buttonPlayNow]];
        
        [[self labelTitle] setText:[NSString stringWithFormat:@"UNAVAILABLE: %@", [[self song] name]]];
        
        [[self labelAddToPlaylist] setText:@"Unavailable"];
    }
    
    if ([[DownloadsManager shared] isSongDownloaded:[self song]])
    {
        [self disableButton:[self buttonDownload]];
        [[self labelDownload] setText:@"Downloaded"];
    }
    
    if ([[self song] availability] == DOWNLOADING)
    {
        [self disableButton:[self buttonDownload]];
        [[self labelDownload] setText:@"Downloading"];
    }
    
    if ([[Playlist shared] currentSong] && [[Playlist shared] songInPlaylistWithSong:[self song]] == [[Playlist shared] currentSong])
    {
        [self disableButton:[self buttonPlayNext]];
        [[self labelPlayNext] setText:@"Current Song"];
    
        if ([[Player shared] currentStatus] != NOT_STARTED)
        {
            [self disableButton:[self buttonPlayNow]];
            [[self labelPlayNow] setText:@"Playing Now"];
        }
    }
}

- (void)disableButton: (UIButton *) button
{
    [button setEnabled:NO];
    
    if (button == [self buttonDownload])
        [[self labelDownload] setTextColor:[UIColor lightTextColor]];
    if (button == [self buttonAddToPlaylist])
        [[self labelAddToPlaylist] setTextColor:[UIColor lightTextColor]];
    if (button == [self buttonPlayNext])
        [[self labelPlayNext] setTextColor:[UIColor lightTextColor]];
    if (button == [self buttonPlayNow])
        [[self labelPlayNow] setTextColor:[UIColor lightTextColor]];
}

- (IBAction)playNow:(UIButton *)sender
{
    if ([[Playlist shared] indexOfSong:[self song]] == NSNotFound)
        [[Playlist shared] addSong:[self song] After:[[Playlist shared] currentSong] Origin:[self origin]];

    if ([[Player shared] isOfflineModeOn])
    {
        [[[UIAlertView alloc] initWithTitle:@"Offline Mode is On" message:@"This song will use data. Turn off offline mode to play this song." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }
    else
    {
        [[Player shared] loadSong:[[Playlist shared] songInPlaylistWithSong:[self song]] ShouldPlay:YES];
        [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Song Options" forKey:@"How"]];
        [self close];
    }
}

- (IBAction)playNext:(UIButton *)sender
{
    if ([[Playlist shared] indexOfSong:[self song]] != NSNotFound)
        [[Playlist shared] moveSong:[[Playlist shared] songInPlaylistWithSong:[self song]] After:[[Playlist shared] currentSong]];
    else
        [[Playlist shared] addSong:[self song] After:[[Playlist shared] currentSong] Origin:[self origin]];
    [self close];
}

- (IBAction)addToPlaylist:(UIButton *)sender
{
    [[Playlist shared] addSongInEnd:[self song] Origin:[self origin]];
    [self close];
}

- (IBAction)download:(UIButton *)sender
{
    [[DownloadsManager shared] downloadSong:[[self song] copy] Origin:[self origin]];
    [self close];
}

- (IBAction)cancel:(UIButton *)sender
{
    [self close];
}

- (void)close
{
    [self willMoveToParentViewController:nil];
    [[self blurView] hide];
    [self removeFromParentViewController];
}

@end
