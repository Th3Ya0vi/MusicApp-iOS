//
//  DownloadsViewController.m
//  Music
//
//  Created by Tushar Soni on 12/5/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "DownloadsViewController.h"
#import "User.h"
#import "Player.h"
#import "SongOptionsViewController.h"

#define currentRowAvailability [[[self searchResults] objectAtIndex:indexPath.row] availability]
#define didCurrentRowFailed    currentRowAvailability != LOCAL && currentRowAvailability != DOWNLOADING

@interface DownloadsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableDownloads;
@property (weak, nonatomic) IBOutlet UILabel *labelDownloadSongs;
@property (strong, nonatomic) NSMutableArray *searchResults;

@end

@implementation DownloadsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Downloads"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"cloud_downloads"]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fillData) name:@"didStartDownloadingSong" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidProgress:) name:@"DownloadingSong" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fillData) name:@"DownloadedSong" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"didStartDownloadingSong"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"DownloadingSong"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"DownloadedSong"];
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[self tableDownloads] setBackgroundColor:[UIColor clearColor]];
    [self.tableDownloads setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self fillData];
}

- (void)setBadge
{
    __block NSUInteger downloadingCount = 0;
    [[self searchResults] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj availability] == DOWNLOADING)
            downloadingCount++;
    }];
    
    (downloadingCount > 0) ? [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", downloadingCount]] : [[self tabBarItem] setBadgeValue:nil];
}

#pragma mark - Table Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (didCurrentRowFailed)
        return 65;
    return (currentRowAvailability == LOCAL) ? 65: 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[[User currentUser] downloads] count] == 0)
    {
        [[self labelDownloadSongs] setHidden:NO];
        [[self tableDownloads] setHidden:YES];
    }
    else
    {
        [[self labelDownloadSongs] setHidden:YES];
        [[self tableDownloads] setHidden:NO];
    }
    return ([self searchResults]) ? [[self searchResults] count] : [[self searchResults] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return currentRowAvailability == LOCAL;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"SubtitleCell";
    NSString *cellNib = @"SubtitleCellView";
    
    Song *song = [[self searchResults] objectAtIndex:indexPath.row];
    
    if ([song availability] == DOWNLOADING)
    {
        cellIdentifier = @"ProgressCell";
        cellNib = @"ProgressCellView";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    UILabel *labelTitle = (UILabel *)[cell viewWithTag:100];
    UILabel *labelSubtitle = (UILabel *)[cell viewWithTag:101];
    
    [labelTitle setText:[song name]];
    [labelSubtitle setText:[[song album] name]];

    if ([song availability] != LOCAL && [song availability] != DOWNLOADING)
        [labelSubtitle setText:@"FAILED TO DOWNLOAD"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Song *songToDelete = [[self searchResults] objectAtIndex:indexPath.row];
        [songToDelete deleteLocalFile];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (currentRowAvailability == LOCAL || (didCurrentRowFailed))
    {
        Song *song = [[self searchResults] objectAtIndex:indexPath.row];
        
        SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:@"Downloads"];
        [[self tabBarController] setModalPresentationStyle:UIModalPresentationCurrentContext];
        [[self tabBarController] presentViewController:songOptions animated:NO completion:nil];
    }
    
}

#pragma mark - Search bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        NSPredicate *songsPredicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", @"name", searchText];
        [self setSearchResults:[[[[User currentUser] downloads] filteredArrayUsingPredicate:songsPredicate] mutableCopy]];
        [[self tableDownloads] reloadData];
    }
    else
        [self fillData];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setText:@""];
    [self fillData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setText:@""];
    [self fillData];
    [searchBar resignFirstResponder];
}

#pragma mark - Others

- (void) downloadDidProgress: (NSNotification *)notification
{
dispatch_async(dispatch_get_main_queue(), ^{
    
    [self setBadge];
    
    NSDictionary *progress = [notification object];
    Song *song = [progress objectForKey:@"Song"];
    float progressValue = [[progress objectForKey:@"Progress"] floatValue];
    
    NSInteger index = [[self searchResults] indexOfObject:song];
    if (index >= 0 == NO)
        return;
    
    UITableViewCell *cell = [[self tableDownloads] cellForRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:102];
    [progressView setProgress: progressValue animated:YES];
    
});
}

- (void) fillData
{
    [self cleanDownloads];

    [self setSearchResults:[[User currentUser] downloads]];

    [[self searchResults] sortUsingComparator:^NSComparisonResult(Song *obj1, Song *obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];
    
    [self setBadge];
    [[self tableDownloads] reloadData];
}

- (void) cleanDownloads
{
    return;
    [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj availability] != DOWNLOADING && [obj availability] != LOCAL)
            [[[User currentUser] downloads] removeObject:obj];
    }];
}

@end
