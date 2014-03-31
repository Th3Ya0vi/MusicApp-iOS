//
//  AlbumViewController.m
//  Music
//
//  Created by Tushar Soni on 11/27/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AlbumViewController.h"
#import "Song.h"
#import "UIImageView+AFNetworking.h"
#import "User.h"
#import "AlbumArtManager.h"
#import "FXBlurView.h"
#import "Player.h"
#import "SongOptionsViewController.h"
#import "Analytics.h"
#import "DownloadsManager.h"
#import "Playlist.h"
#import "AFNetworkReachabilityManager.h"
#import "RNBlurModalView.h"

@interface AlbumViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbumArt;
@property (weak, nonatomic) IBOutlet UIButton *buttonDownloadAll;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddAllPlaylist;

@property (nonatomic) NSInteger selectedRow;

@end

@implementation AlbumViewController

- (id)initWithAlbum: (Album *) album Origin: (NSString *)origin
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        [self setAlbum:album];
        [self setOrigin:origin];
        [self setDownloadsOnly:NO];
        
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
        [[self navigationItem] setRightBarButtonItem:closeButton];
    }
    
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *blackMask = [[UIView alloc] initWithFrame:[[self imageBackground] frame]];
    [blackMask setFrame:CGRectMake(0, 0, [[self imageBackground] frame].size.width, [[self imageBackground] frame].size.height)];
    [blackMask setBackgroundColor:[UIColor blackColor]];
    [blackMask setAlpha:0.15];
    [[self imageBackground] addSubview:blackMask];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[User currentUser] save];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"AlbumView"];
}

- (void)updateUI
{
    [self setTitle:[[self album] name]];
    [self setAlbumArt];
}

- (void) setAlbumArt
{
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:[self album] Size:BIG From:@"AlbumView" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
        
        [[self imageAlbumArt] setImage:image];
        [[self imageBackground] setImage:[image blurredImageWithRadius:50 iterations:2 tintColor:[UIColor clearColor]]];
    }];
}

#pragma mark - Table Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.album.songs count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SubtitleCell";
    static NSString *cellNib = @"SubtitleCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    UILabel *lblTitle = (UILabel *)[cell viewWithTag:100];
    UILabel *lblSubtitle = (UILabel *)[cell viewWithTag:101];
    
    Song *song = [self.album.songs objectAtIndex:indexPath.row];
    
    lblTitle.text = [song name];
    lblSubtitle.text = [[song singers] componentsJoinedByString:@", "];
    
    if ([self downloadsOnly] && [song availability] == CLOUD)
        [[cell contentView] setAlpha:0.3];
    else
        [[cell contentView] setAlpha:1.0];
    
    return cell;
}

#pragma mark Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    Song *song = [[[self album] songs] objectAtIndex:indexPath.row];
    Album *albumCopy = [[self album] copy];
    [albumCopy setSongs:nil];
    [song setAlbum:albumCopy];
    
    SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:[self origin]];
    [self addChildViewController:songOptions];
    RNBlurModalView *blurView = [[RNBlurModalView alloc] initWithViewController:self view:[songOptions view]];
    [songOptions setBlurView:blurView];
    [songOptions setIsBackgroundTransparent:YES];
    [blurView show];
}

#pragma mark Others

- (void)songIsUnavailable
{
    [[[UIAlertView alloc] initWithTitle:@"Sorry!" message:@"This song is currently unavailable." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

- (IBAction)downloadAllSongs:(id)sender
{
    if ([[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi])
        [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Download all songs from this album?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    else
        [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Download all songs from this album? NOTE: You are currently using celluar data." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

- (IBAction)addAllSongsToPlaylist:(id)sender
{
    [[[self album] songs] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        Album *albumCopy = [[self album] copy];
        [albumCopy setSongs:nil];
        [obj setAlbum:albumCopy];
        [[Playlist shared] addSongInEnd:obj Origin:[self origin]];
    }];
    [[Analytics shared] logEventWithName:EVENT_SONG_ADD_ALL];
    
    [[self buttonAddAllPlaylist] setEnabled:NO];
    
    [[[UIAlertView alloc] initWithTitle:@"All songs have been added to the playlist" message:Nil delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[[self album] songs] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
            Album *albumCopy = [[self album] copy];
            [albumCopy setSongs:nil];
            [obj setAlbum:albumCopy];
            [[DownloadsManager shared] downloadSong:[obj copy] Origin:[self origin]];
        }];
        [[Analytics shared] logEventWithName:EVENT_DOWNLOAD_ALL];
        
        [[self buttonDownloadAll] setEnabled:NO];
        
        [[[UIAlertView alloc] initWithTitle:@"All songs are downloading.." message:@"Check the Downloads tab for progress." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }
}

@end
