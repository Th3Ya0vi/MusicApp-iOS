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
#import "DownloadsManager.h"
#import "Analytics.h"
#import "RNBlurModalView.h"
#import "AlbumViewController.h"
#import "BollywoodAPIClient.h"
#import "AlbumArtManager.h"
#import "UpsellViewController.h"

@interface DownloadsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableDownloads;
@property (weak, nonatomic) IBOutlet UILabel *labelDownloadSongs;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *searchResults;
@property (nonatomic) BOOL showingBySongs;
@end

@implementation DownloadsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setShowingBySongs:YES];
        [self setTitle:@"Downloads"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"cloud_downloads"]];
        
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editDownloads)];
        [[self navigationItem] setLeftBarButtonItem:editButton];
        UIBarButtonItem *showByButton = [[UIBarButtonItem alloc] initWithTitle:@"Albums" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleShowBy:)];
        [[self navigationItem] setRightBarButtonItem:showByButton];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fillData) name:@"didStartDownloadingSong" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadDidProgress:) name:@"DownloadingSong" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fillData) name:@"DownloadedSong" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didStartDownloadingSong" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadingSong" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadedSong" object:nil];
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[self tableDownloads] setBackgroundColor:[UIColor clearColor]];
    
    UpsellViewController *upsellVC = [[UpsellViewController alloc] initWithOrigin:@"Downloads"];
    [self addChildViewController:upsellVC];
    [[self tableDownloads] setTableFooterView:[upsellVC view]];
    [upsellVC didMoveToParentViewController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([[[User currentUser] downloads] count] == 0)
    {
        [[self labelDownloadSongs] setHidden:NO];
        [[self tableDownloads] setHidden:YES];
    }
    else
    {
        [[self labelDownloadSongs] setHidden:YES];
        [[self tableDownloads] setHidden:NO];
        [self fillData];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Downloads"];
}

- (void)setBadge
{
    NSUInteger downloadingCount = [[DownloadsManager shared] currentNumberOfDownloadTasks];
    (downloadingCount > 0) ? [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", downloadingCount]] : [[self tabBarItem] setBadgeValue:nil];
}

#pragma mark - Table Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingBySongs])
        return 95;
    
    if ((didCurrentRowFail) ||
        currentRowAvailability == LOCAL)
        return 60;
    
    return 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([self searchResults]) ? [[self searchResults] count] : [[self searchResults] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ![self showingBySongs] || currentRowAvailability == LOCAL || (didCurrentRowFail);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"OrderedCell";
    NSString *cellNib = @"OrderedCellView";
    
    if ([self showingBySongs] &&
        [[[self searchResults] objectAtIndex:indexPath.row] availability] == DOWNLOADING)
    {
        cellIdentifier = @"ProgressCell";
        cellNib = @"ProgressCellView";
    }
    if (![self showingBySongs])
    {
        cellIdentifier = @"ImageSubtitleCell";
        cellNib = @"ImageSubtitleCellView";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    [cell setClipsToBounds:YES];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    
    if ([self showingBySongs])
    {
        UILabel *labelNumber = (UILabel *)[cell viewWithTag:100];
        UILabel *labelTitle = (UILabel *)[cell viewWithTag:101];
        UILabel *labelSubtitle = (UILabel *)[cell viewWithTag:102];
        
        Song *song = [[self searchResults] objectAtIndex:indexPath.row];
        
        [labelNumber setText:[NSString stringWithFormat:@"%d", indexPath.row + 1]];
        [labelTitle setText:[song name]];
        [labelSubtitle setText:[[song album] name]];
    }
    else
    {
        UIImageView *imageAlbumArt = (UIImageView *)[cell viewWithTag:102];
        UILabel *labelTitle = (UILabel *)[cell viewWithTag:100];
        UILabel *labelSubtitle = (UILabel *)[cell viewWithTag:101];
        
        Album *album = [[self searchResults] objectAtIndex:indexPath.row];
        [labelTitle setText:[album name]];
        [labelSubtitle setText:[NSString stringWithFormat:@"%d", [album year]]];
        
        [[AlbumArtManager shared] fetchAlbumArtForAlbum:album Size:SMALL From:@"Downloads" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
            [imageAlbumArt setImage:image];
        }];
    }
    
    if ([self showingBySongs] &&
        [[[self searchResults] objectAtIndex:indexPath.row] availability] != LOCAL &&
        [[[self searchResults] objectAtIndex:indexPath.row] availability] != DOWNLOADING)
    {
        [[cell contentView] setAlpha:0.2];
    }
    else
    {
        [[cell contentView] setAlpha:1.0];
    }

    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if ([self showingBySongs])
        {
            Song *songToDelete = [[self searchResults] objectAtIndex:indexPath.row];
            [[DownloadsManager shared] deleteSongFromDownloads:songToDelete];
            
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                [self fillData];
            }];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [tableView endUpdates];
            [CATransaction commit];
        }
        else
        {
            Album *albumToDelete = [[self searchResults] objectAtIndex:indexPath.row];
            [[DownloadsManager shared] deleteAlbumFromDownloads:albumToDelete];
            [self fillData];
        }
    }
}


#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self searchBar] resignFirstResponder];
    
    if ([self showingBySongs] && (currentRowAvailability == LOCAL || (didCurrentRowFail)))
    {
        Song *song = [[self searchResults] objectAtIndex:indexPath.row];
        SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:@"Downloads"];
        [self addChildViewController:songOptions];
        RNBlurModalView *blurView = [[RNBlurModalView alloc] initWithViewController:self view:[songOptions view]];
        [songOptions setBlurView:blurView];
        [blurView showWithDuration:0.1 delay:0 options:kNilOptions completion:^{
            [songOptions didMoveToParentViewController:self];
        }];;
    }
    else if ([self showingBySongs] == NO)
    {
        Album *album = [[self searchResults] objectAtIndex:indexPath.row];
        [[BollywoodAPIClient shared] fetchAlbumWithAlbumID:[album albumid] CompletionBlock:^(Album *album) {
            AlbumViewController *albumVC = [[AlbumViewController alloc] initWithAlbum:album Origin:@"Downloads"];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:albumVC];
            [albumVC setDownloadsOnly:YES];
            [[self tabBarController] presentViewController:navController animated:YES completion:nil];
        }];
    }
    
}

#pragma mark - Search bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        NSPredicate *songsPredicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", @"name", searchText];
        if ([self showingBySongs])
            [self setSearchResults:[[[[User currentUser] downloads] filteredArrayUsingPredicate:songsPredicate] mutableCopy]];
        else
            [self setSearchResults:[[[[DownloadsManager shared] uniqueAlbumsWithNoData] filteredArrayUsingPredicate:songsPredicate] mutableCopy]];
        
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
    
    if (![self showingBySongs]) return;
    
    NSDictionary *progress = [notification object];
    Song *song = [progress objectForKey:@"Song"];
    float progressValue = [[progress objectForKey:@"Progress"] floatValue];
    
    NSInteger index = [[self searchResults] indexOfObject:song];
    if (index == NSNotFound)
        return;
    
    UITableViewCell *cell = [[self tableDownloads] cellForRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:103];
    [progressView setProgress: progressValue animated:YES];
    
});
}

- (void) fillData
{
    if ([self showingBySongs])
        [self setSearchResults:[[User currentUser] downloads]];
    else
        [self setSearchResults:[[DownloadsManager shared] uniqueAlbumsWithNoData]];
    
    [[self searchResults] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];
    [self setBadge];
    [[self tableDownloads] reloadData];
}

- (void)editDownloads
{
    if ([[self tableDownloads] isEditing])
    {
        [[self tableDownloads] setEditing:NO animated:YES];
        [[[self navigationItem] leftBarButtonItem] setTitle:@"Edit"];
    }
    else
    {
        [[self tableDownloads] setEditing:YES animated:YES];
        [[[self navigationItem] leftBarButtonItem] setTitle:@"Done"];
    }
}

- (void)toggleShowBy: (UIBarButtonItem *)sender
{
    [self setShowingBySongs:![self showingBySongs]];
    sender.title = ([self showingBySongs]) ? @"Albums" : @"Songs";
    [self fillData];
    [[self tableDownloads] reloadData];
}

@end
