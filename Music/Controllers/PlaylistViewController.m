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
#import "Activity.h"

@interface PlaylistViewController ()

@property (weak, nonatomic) IBOutlet BVReorderTableView *tablePlaylist;

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
        
        UIBarButtonItem *shuffleButton = [[UIBarButtonItem alloc] initWithTitle:@"Shuffle" style:UIBarButtonItemStylePlain target:self action:@selector(shuffle)];
        [self.navigationItem setLeftBarButtonItem:shuffleButton];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(shuffle)];
        [swipe setDirection:UISwipeGestureRecognizerDirectionRight];
        [[self view] addGestureRecognizer:swipe];

    }
    return self;
}

#pragma mark - View

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

#pragma mark - Table Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[User currentUser] playlist] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isCurrent = indexPath.row == [[User currentUser] currentPlaylistIndex];
    
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
    
    title.text = [[[[User currentUser] playlist] objectAtIndex:indexPath.row] name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSInteger currentIndex = [[User currentUser] currentPlaylistIndex];
        
        if (indexPath.row < currentIndex || indexPath.row == [[[User currentUser] playlist] count])
            [[User currentUser] setCurrentPlaylistIndex:currentIndex - 1];
        
        [[[[User currentUser] playlist] objectAtIndex:indexPath.row] removeFromPlaylistAndPostNotification];
        
        if ([[[User currentUser] playlist] count] == 0)
            [[User currentUser] setCurrentPlaylistIndex:0];
        
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
    if ([[Player shared] currentStatus] != STOPPED)
        [Activity addWithSong:[Song currentSongInPlaylist] action:FINISHEDLISTENING extra:[NSString stringWithFormat:@"%f", [[Player shared] getPercentCompleted]]];
    [[User currentUser] setCurrentPlaylistIndex:indexPath.row];
    [[Player shared] loadCurrentSong];
    [tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([[Player shared] currentStatus] == PLAYING && [[User currentUser] currentPlaylistIndex] == indexPath.row) ? NO : YES;
}

#pragma mark Table Row Draggable Delegate

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[User currentUser] playlist] objectAtIndex:indexPath.row];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Song *song = [[[User currentUser] playlist] objectAtIndex:fromIndexPath.row];
    [[[User currentUser] playlist] removeObjectAtIndex:fromIndexPath.row];
    [[[User currentUser] playlist] insertObject:song atIndex:toIndexPath.row];
    
    NSInteger currentIndex = [[User currentUser] currentPlaylistIndex];
    
    if (fromIndexPath.row == currentIndex)
        [[User currentUser] setCurrentPlaylistIndex:toIndexPath.row];
    else if(fromIndexPath.row < currentIndex && toIndexPath.row >= currentIndex)
        [[User currentUser] setCurrentPlaylistIndex:currentIndex - 1];
    else if(fromIndexPath.row > currentIndex && toIndexPath.row <= currentIndex)
        [[User currentUser] setCurrentPlaylistIndex:currentIndex + 1];
        
}

- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    [[[User currentUser] playlist] replaceObjectAtIndex:indexPath.row withObject:object];
}

#pragma mark - Others

- (void)shuffle
{
    User *user = [User currentUser];
    Song *currentSong = [[user playlist] objectAtIndex:[user currentPlaylistIndex]];
    NSMutableArray *playlistCopy = [[user playlist] mutableCopy];
    
    [playlistCopy sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        return rand()%100 < 50;
    }];
    
    [user setCurrentPlaylistIndex:[playlistCopy indexOfObject:currentSong]];
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:[[user playlist] count]]
    ;
    [[user playlist] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [[user playlist] removeAllObjects];
    [[self tablePlaylist] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
    [user setPlaylist:playlistCopy];
    [[self tablePlaylist] insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
    
    [Activity addWithSong:[Song currentSongInPlaylist] action:SHUFFLED];
}

- (void)closeView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
