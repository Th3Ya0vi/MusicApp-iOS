//
//  PlaylistViewController.m
//  Music
//
//  Created by Tushar Soni on 12/11/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "PlaylistViewController.h"
#import "BVReorderTableView.h"
#import "User.h"
#import "Playlist.h"
#import "SongOptionsViewController.h"
#import "Analytics.h"

@interface PlaylistViewController ()

@property (weak, nonatomic) IBOutlet UIButton *buttonOfflineMode;
@property (weak, nonatomic) IBOutlet BVReorderTableView *tablePlaylist;
@property (nonatomic) BOOL isShuffling;

@end

@implementation PlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Playlist"];
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
        [self.navigationItem setRightBarButtonItem:closeButton];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(shuffle:)];
        [swipe setDirection:UISwipeGestureRecognizerDirectionRight];
        [[self view] addGestureRecognizer:swipe];
        
        [self setIsShuffling:NO];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"SongFinished" object:Nil queue:nil usingBlock:^(NSNotification *note) {
            [[self tablePlaylist] reloadData];
        }];
    }
    return self;
}

#pragma mark - View

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SongFinished" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self tablePlaylist] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[User currentUser] save];
    
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self buttonOfflineMode] setSelected:[[Player shared] isOfflineModeOn]];
    [[self tablePlaylist] reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Playlist"];
}

#pragma mark - Table Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([self isShuffling]) ? 0 : [[Playlist shared] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isCurrent = indexPath.row == [[Playlist shared] currentIndex];
    
    NSString *cellIdentifier = (isCurrent) ? @"PlayingCell" : @"OrderedCell";
    NSString *cellNib = (isCurrent) ? @"PlayingCellView" : @"OrderedCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    UILabel *number = (UILabel *)[cell viewWithTag:100];
    UILabel *title = (UILabel *)[cell viewWithTag:101];
    
    if (isCurrent)
        [number setText: @""];
    else
        [number setText: [NSString stringWithFormat:@"%d.", indexPath.row + 1]];
    
    [title setText:[[[Playlist shared] songAtIndex:indexPath.row] name]];
    
    
    [UIView animateWithDuration:0.2 animations:^{
        if ([[Player shared] isOfflineModeOn] && [[[Playlist shared] songAtIndex:indexPath.row] availability] == CLOUD)
            [[cell contentView] setAlpha:0.2];
        else
            [[cell contentView] setAlpha:1];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[Playlist shared] removeSongAtIndex:indexPath.row];

        [CATransaction begin];
        [tableView beginUpdates];
        [CATransaction setCompletionBlock:^{
            [tableView reloadData];
        }];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [tableView endUpdates];
        [CATransaction commit];
    }
}

#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Song *songToPlay = [[Playlist shared] songAtIndex:indexPath.row];
    if ([[Player shared] isOfflineModeOn] && [songToPlay availability] != LOCAL)
    {
        [[[UIAlertView alloc] initWithTitle:@"Offline Mode is On" message:@"This song will use data. Turn off offline mode to play this song." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }
    else
    {
        [[Player shared] loadSong:songToPlay ShouldPlay:YES];
        [tableView reloadData];
        [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Playlist" forKey:@"How"]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (previousSongInPlaylist && [[Playlist shared] currentIndex] == indexPath.row) ? NO : YES;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:[[Playlist shared] songAtIndex:indexPath.row] Origin:@"Playlist"];
    [[self navigationController] setModalPresentationCapturesStatusBarAppearance:YES];
    [[self navigationController] setModalPresentationStyle:UIModalPresentationCurrentContext];
    [[self navigationController] presentViewController:songOptions animated:NO completion:nil];
}

#pragma mark Table Row Draggable Delegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[Playlist shared] songAtIndex:indexPath.row];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [[Playlist shared] swapSong:[[Playlist shared] songAtIndex:fromIndexPath.row] With:[[Playlist shared] songAtIndex:toIndexPath.row]];
}

- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    
}

#pragma mark - Others

- (IBAction)shuffle:(id)sender
{
    [self setIsShuffling:YES];
    [[Playlist shared] shuffle];
 
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[[Playlist shared] count]];
    
    for (int i=0;i<[[Playlist shared] count];i++)
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    
    [[self tablePlaylist] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
    
    [self setIsShuffling:NO];
    
    [[self tablePlaylist] insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    
    [[Analytics shared] logEventWithName:EVENT_SHUFFLE Attributes:[NSDictionary dictionaryWithObject:([sender isKindOfClass:[UISwipeGestureRecognizer class]]) ? @"Yes" : @"No" forKey:@"Swipe"]];
}

- (IBAction)clearPlaylist:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to clear your playlist?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes" , nil] show];
}

- (IBAction)toggleOfflineMode:(UIButton *)sender
{
    [[Player shared] setIsOfflineModeOn:![[Player shared] isOfflineModeOn]];
    [sender setSelected:[[Player shared] isOfflineModeOn]];
    
    if ([[Player shared] isOfflineModeOn] && [[[Playlist shared] currentSong] availability] != LOCAL)
    {
        Song *nextSong = nextLocalSongInPlaylist;
        if (nextSong == nil)
            nextSong = previousLocalSongInPlaylist;
        
        if (nextSong)
            [[Player shared] loadSong:nextLocalSongInPlaylist ShouldPlay:isPlayerPlaying];
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"No Downloaded Songs In Playlist" message:@"You need downloaded songs in your playlist to switch to offline mode." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
            [[Player shared] setIsOfflineModeOn:NO];
            [sender setSelected:NO];
        }
    }
    
    [[self tablePlaylist] reloadData];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [[Player shared] stop];
        [[Playlist shared] clear];
        [self closeView];
    }
}

- (void)closeView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
