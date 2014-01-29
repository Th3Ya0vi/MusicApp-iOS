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

@interface DownloadsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableDownloads;
@property (weak, nonatomic) IBOutlet UILabel *labelDownloadSongs;
@property (strong, nonatomic) NSMutableArray *downloadedSongs;
@property (strong, nonatomic) NSMutableArray *downloadingSongs;
@property (nonatomic) NSInteger selectedRow;

@end

@implementation DownloadsViewController

- (id)initWithNib
{
    self = [super initWithNibName:@"DownloadsView" bundle:nil];
    if (self)
    {
        [self setTitle:@"Downloads"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"cloud_downloads"]];
        self.downloadedSongs = [[NSMutableArray alloc] init];
        self.downloadingSongs = [[NSMutableArray alloc] init];
        
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
    ([[self downloadingSongs] count] > 0) ? [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", [[self downloadingSongs] count]]] : [[self tabBarItem] setBadgeValue:nil];        
}

#pragma mark - Table Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0) ? 65 : 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger downloadedSongs = [[self downloadedSongs] count];
    NSInteger downloadingSongs = [[self downloadingSongs] count];
    
    if (downloadedSongs == 0 && downloadingSongs == 0)
    {
        [[self labelDownloadSongs] setHidden:NO];
        [[self tableDownloads] setHidden:YES];
    }
    else
    {
        [[self labelDownloadSongs] setHidden:YES];
        [[self tableDownloads] setHidden:NO];
    }
    
    return (section == 0) ? downloadedSongs : downloadingSongs;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1 && [[self downloadingSongs] count] == 0)
        return nil;
    
    return (section == 0) ? @"Downloaded" : @"Downloading";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0) ? YES : NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0) ? [self cellForDownloadsSectionForRow:indexPath.row Table:tableView] : [self cellForDownloadingSectionForRow:indexPath.row Table:tableView];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        Song *songToDelete = [[self downloadedSongs] objectAtIndex:indexPath.row];
        [songToDelete deleteLocalFile];
        [[self downloadedSongs] removeObject:songToDelete];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0)
    {
        [self setSelectedRow:indexPath.row];
        
        Song *song = [[self downloadedSongs] objectAtIndex:indexPath.row];
        
        SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:@"Downloads"];
        [[self tabBarController] setModalPresentationStyle:UIModalPresentationCurrentContext];
        [[self tabBarController] presentViewController:songOptions animated:NO completion:nil];
    }
    
}

#pragma mark - Table Cells

- (UITableViewCell *)cellForDownloadsSectionForRow: (NSInteger) row Table: (UITableView *)tableView
{
    static NSString *cellIdentifier = @"SubtitleCell";
    static NSString *cellNib = @"SubtitleCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    Song *song = [[self downloadedSongs] objectAtIndex:row];
    
    UILabel *labelTitle = (UILabel *)[cell viewWithTag:100];
    UILabel *labelSubtitle = (UILabel *)[cell viewWithTag:101];
    
    [labelTitle setText:[song name]];
    [labelSubtitle setText:[[song album] name]];

    return cell;
}

- (UITableViewCell *)cellForDownloadingSectionForRow: (NSInteger) row Table: (UITableView *)tableView
{
    static NSString *cellIdentifier = @"ProgressCell";
    static NSString *cellNib = @"ProgressCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    Song *song = [[self downloadingSongs] objectAtIndex:row];
    
    UILabel *labelTitle = (UILabel *)[cell viewWithTag:100];
    UILabel *labelSubtitle = (UILabel *)[cell viewWithTag:101];
    
    [labelTitle setText:[song name]];
    [labelSubtitle setText:[[song album] name]];
    
    return cell;
}

#pragma mark - Others

- (void) downloadDidProgress: (NSNotification *)notification
{
dispatch_async(dispatch_get_main_queue(), ^{
    
    [self setBadge];
    
    NSDictionary *progress = [notification object];
    Song *song = [progress objectForKey:@"Song"];
    float progressValue = [[progress objectForKey:@"Progress"] floatValue];
    
    NSInteger index = [[self downloadingSongs] indexOfObject:song];
    if (index >= 0 == NO)
        return;
    
    UITableViewCell *cell = [[self tableDownloads] cellForRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:1]];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:102];
    [progressView setProgress: progressValue animated:YES];
    
});
}

- (void) fillData
{
    [[self downloadedSongs] removeAllObjects];
    [[self downloadingSongs] removeAllObjects];
    
    [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj availability] == LOCAL)
            [[self downloadedSongs] addObject:obj];
        else if([obj availability] == DOWNLOADING)
            [[self downloadingSongs] addObject:obj];
    }];
    
    [self setBadge];
    
    [[self tableDownloads] reloadData];
}

@end
