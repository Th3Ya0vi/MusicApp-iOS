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
    [[Player shared] loadSong:[[Playlist shared] songAtIndex:indexPath.row] ShouldPlay:YES];
    [tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[Analytics shared] logEventWithName:@"Song Change" Attributes:[NSDictionary dictionaryWithObject:@"Playlist" forKey:@"How"]];
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
    
    [[Analytics shared] logEventWithName:@"Shuffle" Attributes:[NSDictionary dictionaryWithObject:([sender isKindOfClass:[UISwipeGestureRecognizer class]]) ? @"Yes" : @"No" forKey:@"Swipe"]];
}

- (IBAction)clearPlaylist:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to clear your playlist?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes" , nil] show];
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
