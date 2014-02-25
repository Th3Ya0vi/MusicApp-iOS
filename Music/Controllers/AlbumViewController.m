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

@interface AlbumViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbumArt;
@property (weak, nonatomic) IBOutlet UILabel *labelYear;
@property (weak, nonatomic) IBOutlet UILabel *labelCast;
@property (weak, nonatomic) IBOutlet UILabel *labelMusicDirector;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonDownloadAll;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonAddAllPlaylist;

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
        
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAlbumView)];
        [self.navigationItem setRightBarButtonItem:closeButton];
    }
    
    return self;
}

#pragma mark - View

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

    if ([self.album year]>0)
        [[self labelYear] setText:[NSString stringWithFormat:@"%ld", (long)[self.album year]]];
    else
        [[self labelYear] setText:@""];
    
    [[self labelCast] setText:[[self.album cast] componentsJoinedByString:@", "]];
    [[self labelMusicDirector] setText:[[self.album musicDirector] componentsJoinedByString:@", "]];
    
    [self setAlbumArt];
}

- (void) setAlbumArt
{
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:[self album] Size:SMALL From:@"AlbumView" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
        
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
    return 65;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Songs";
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
    
    return cell;
}

#pragma mark Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Song *song = [[[self album] songs] objectAtIndex:indexPath.row];
    Album *albumCopy = [[self album] copy];
    [albumCopy setSongs:nil];
    [song setAlbum:albumCopy];
    
    SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:[self origin]];
    [[self navigationController] setModalPresentationCapturesStatusBarAppearance:YES];
    [[self navigationController] setModalPresentationStyle:UIModalPresentationCurrentContext];
    [[self navigationController] presentViewController:songOptions animated:NO completion:nil];
}

#pragma mark Others

- (void)closeAlbumView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)songIsUnavailable
{
    [[[UIAlertView alloc] initWithTitle:@"Sorry!" message:@"This song is currently unavailable." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

- (IBAction)reportIncorrectData:(UIButton *)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Thanks" message:nil delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

- (IBAction)downloadAllSongs:(id)sender
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
    
    [[[UIAlertView alloc] initWithTitle:@"All songs have been added to the playlist" message:@"Go to your Playlist to listen to them." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

@end
