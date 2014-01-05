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
#import "Activity.h"
#import "User.h"
#import "AlbumArtManager.h"
#import "FXBlurView.h"
#import "Player.h"

@interface AlbumViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbumArt;
@property (weak, nonatomic) IBOutlet UILabel *labelYear;
@property (weak, nonatomic) IBOutlet UILabel *labelCast;
@property (weak, nonatomic) IBOutlet UILabel *labelMusicDirector;

@property (nonatomic) NSInteger selectedRow;

@end

@implementation AlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
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
        [[self imageBackground] setImage:image];
        FXBlurView *blur = [[FXBlurView alloc] initWithFrame:CGRectMake(0, 0, 320, 170)];
        [blur setTintColor:[UIColor blackColor]];
        [blur setDynamic:NO];
        [[self imageBackground] addSubview:blur];
        
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
    Song *song = [self.album.songs objectAtIndex:indexPath.row];
    if ([song availability] == CLOUD)
    {
        UIAlertView *options = [[UIAlertView alloc] initWithTitle:[song name] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Play Now", @"Add to Playlist", @"Download", nil];
        self.selectedRow = indexPath.row;
        [options show];
    }
    else if([song availability] == LOCAL)
    {
        UIAlertView *options = [[UIAlertView alloc] initWithTitle:[song name] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Play Now", @"Add to Playlist", nil];
        self.selectedRow = indexPath.row;
        [options show];
    }
    else if([song availability] == UNAVAILABLE)
    {
        [self songIsUnavailable];
        [Activity addWithSong:song action:INCORRECTDATA];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    Song *song = [self.album.songs objectAtIndex:self.selectedRow];
    Album *albumCopy = [[self album] copy];
    [albumCopy setSongs:nil];
    [song setAlbum:albumCopy];
    switch (buttonIndex)
    {
        case 1:
            [song addToPlaylistAndPostNotificationWithOrigin:@"Search"];
            [[User currentUser] setCurrentPlaylistIndex:[[[User currentUser] playlist] count] - 1];
            [[Player shared] loadCurrentSong];
            [[Player shared] play];
            break;
        case 2:
            [song addToPlaylistAndPostNotificationWithOrigin:@"Search"];
            break;
        case 3:
            [song startDownloadWithOrigin:[self origin]];
            break;
        default:
            break;
    }
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
    [Activity addWithSong:[[[self album] songs] firstObject] action:INCORRECTDATA];
    [[[UIAlertView alloc] initWithTitle:@"Thanks" message:nil delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

@end
