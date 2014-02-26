//
//  SearchViewController.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "SearchViewController.h"
#import "Song.h"
#import "User.h"
#import "AlbumViewController.h"
#import "AlbumArtManager.h"
#import "UIImageView+AFNetworking.h"
#import "Player.h"
#import "SongOptionsViewController.h"
#import "BollywoodAPIClient.h"
#import "Analytics.h"

@interface SearchViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewResults;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (nonatomic) enum SearchScope selectedScope;
@property (nonatomic) BOOL isFinalSearch;
@property (strong, nonatomic) NSArray *results;
@property (strong, nonatomic) NSMutableArray *subViews;
@property (nonatomic) NSInteger selectedRow;

@end

@implementation SearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0];;
        self.selectedScope = ALBUM;
        self.title = @"Search";
        self.subViews = [[NSMutableArray alloc] initWithCapacity:2];
        
        self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    }
    return self;
}

#pragma mark - View

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[AlbumArtManager shared] cancelFromSender:@"SearchView"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Search"];
}

#pragma mark Table Data Source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ([self results]) ? [[self results] count] : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self selectedScope] == SONG || [self isFinalSearch] == NO) ? 65 : 95;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier;
    NSString *cellNib;
    
    if ([self selectedScope] == ALBUM && [self isFinalSearch])
    {
        cellIdentifier = @"ImageSubtitleCell";
        cellNib = @"ImageSubtitleCellView";
    }
    else
    {
        cellIdentifier = @"SubtitleCell";
        cellNib = @"SubtitleCellView";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [bundle firstObject];
    }
    
    UILabel *lblTitle = (UILabel *)[cell viewWithTag:100];
    UILabel *lblSubtitle = (UILabel *)[cell viewWithTag:101];
    
    if ([self selectedScope] == SONG)
    {
        Song *song = [self.results objectAtIndex:indexPath.row];
        
        lblTitle.text = [song name];
        
        if ([[song album] year]>0)
            lblSubtitle.text = [NSString stringWithFormat:@"%@ (%ld)", [[song album] name], (long)[[song album] year]];
        else
            lblSubtitle.text= [NSString stringWithFormat:@"%@", [[song album] name]];
    }
    else
    {
        Album *album = [[self results] objectAtIndex:indexPath.row];
        
        if ([self isFinalSearch])
        {
            UIImageView *imageAlbumArt = (UIImageView *)[cell viewWithTag:102];
            [imageAlbumArt setImage:[UIImage imageNamed:@"DefaultAlbumArt"]];
            
            [[AlbumArtManager shared] fetchAlbumArtForAlbum:album Size:SMALL From:@"SearchView" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
                [imageAlbumArt setImage:image];
            }];
        }
        
        [lblTitle setText:[album name]];
        [lblSubtitle setText:[[album cast] componentsJoinedByString:@", "]];
    }
    
    return cell;
}

#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self selectedScope] == SONG)
    {
        Song *song = [self.results objectAtIndex:indexPath.row];
        
        SongOptionsViewController *songOptions = [[SongOptionsViewController alloc] initWithSong:song Origin:@"Search"];
        [[self tabBarController] setModalPresentationStyle:UIModalPresentationCurrentContext];
        [[self tabBarController] presentViewController:songOptions animated:NO completion:nil];
    }
    else
    {
        AlbumViewController *albumDetails = [[AlbumViewController alloc] initWithAlbum:[[self results] objectAtIndex:indexPath.row] Origin:@"Search"];
        UINavigationController *uiNavControllerForAlbumDetails = [[UINavigationController alloc] initWithRootViewController:albumDetails];
        [[self tabBarController] setModalPresentationStyle:UIModalPresentationNone];
        [[self tabBarController] presentViewController:uiNavControllerForAlbumDetails animated:YES completion:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[self searchField] resignFirstResponder];
}

#pragma mark - Action Methods

- (IBAction)updateScope:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0)
        self.selectedScope = ALBUM;
    else if(sender.selectedSegmentIndex == 1)
        self.selectedScope = SONG;

    self.results = [[NSArray alloc] init];
    [self setIsFinalSearch:YES];
    [self prepareToSearchWithQuery:[[self searchField] text]];
    
}

- (IBAction)updateSearchString:(UITextField *)sender
{
    [self reset];
    [self setIsFinalSearch:NO];
    [self performSelector:@selector(prepareToSearchWithQuery:) withObject:[[self searchField] text] afterDelay:1.0];
}

#pragma mark Text View Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self setIsFinalSearch:YES];
    [self prepareToSearchWithQuery:[textField text]];
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[self navigationItem] setRightBarButtonItem:[self cancelButton]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [[self navigationItem] setRightBarButtonItem:nil];
}

#pragma mark - Others

- (void)loadTableForResults
{
    CGSize size = [[self viewResults] frame].size;
    UITableView *tableResults = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
    
    [tableResults setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [tableResults setDataSource:self];
    [tableResults setDelegate:self];
    
    [tableResults setAlpha:0.0];
    [[self viewResults] addSubview:tableResults];
    [UIView animateWithDuration:0.3 animations:^{
        [tableResults setAlpha:1.0];
    }];
    
    [self.subViews addObject:tableResults];
}

- (void)prepareToSearchWithQuery: (NSString *)query
{
    [self reset];
    
    if ([[self.searchField text] length] < MIN_SEARCH_LENGTH)
    {
        self.results = nil;
        return;
    }
    if (![query isEqualToString:[[self searchField] text]])
        return;
    
    [[self activityIndicator] startAnimating];
    NSLog(@"Starting search!");
    [[BollywoodAPIClient shared] searchFor:[self selectedScope] IsFinal:[self isFinalSearch] Query:[[self searchField] text] Success:^(NSArray *objects) {
        [[self activityIndicator] stopAnimating];
        [self setResults:objects];
        [self loadTableForResults];
    } Failure:^{
        [[[UIAlertView alloc] initWithTitle:@"Can't Connect" message:@"Please make sure you are connected to the internet" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        [self reset];
    }];
}

- (void)songIsUnavailable
{
    [[[UIAlertView alloc] initWithTitle:@"Sorry!" message:@"This song is currently unavailable." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
}

- (void)reset
{
    [[[self viewResults] subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    [[BollywoodAPIClient shared] cancelCurrentSearch];
    [[AlbumArtManager shared] cancelFromSender:@"SearchView"];
    [[self activityIndicator] stopAnimating];
}

- (void)cancelButtonPressed
{
    [[self searchField] resignFirstResponder];
}

@end
