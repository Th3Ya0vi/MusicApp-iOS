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
#import "FXBlurView.h"
#import <QuartzCore/QuartzCore.h>

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

@end

@implementation SongOptionsViewController

- (id)initWithSong: (Song *)song Origin: (NSString *)origin
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        [self setSong:song];
        [self setOrigin:origin];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

+ (UIImage *)screenImage
{
    UIGraphicsBeginImageContextWithOptions([[[UIApplication sharedApplication] delegate] window].bounds.size, NO, [UIScreen mainScreen].scale);
    
    [[[[[UIApplication sharedApplication] delegate] window] layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext()
    ;
    return image;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self view] setAlpha:0.0];
    [self syncView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.2 animations:^{
        [[self view] setAlpha:1.0];
    }];
}

- (void)syncView
{
    [[self labelTitle] setText:[[self song] name]];
    
    if ([[self song] availability] == UNAVAILABLE)
    {
        [self disableButton:[self buttonAddToPlaylist]];
        [self disableButton:[self buttonDownload]];
        [self disableButton:[self buttonPlayNext]];
        [self disableButton:[self buttonPlayNow]];
        
        [[self labelTitle] setText:[NSString stringWithFormat:@"UNAVAILABLE: %@", [[self song] name]]];
        
        [[self labelAddToPlaylist] setText:@"Unavailable"];
    }
    
    if ([[self song] availability] == LOCAL)
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

    [[Player shared] loadSong:[[Playlist shared] songInPlaylistWithSong:[self song]] ShouldPlay:YES];
    
    [self close];
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
    [[self song] startDownloadWithOrigin:[self origin]];
    [self close];
}

- (IBAction)cancel:(UIButton *)sender
{
    [self close];
}

- (void)close
{
    [UIView animateWithDuration:0.2 animations:^{
        [[self view] setAlpha:0.0];
    } completion:^(BOOL finished) {
        if (finished)
            [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end
