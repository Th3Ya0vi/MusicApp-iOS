//
//  ExploreViewController.m
//  Music
//
//  Created by Tushar Soni on 12/18/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "BollywoodAPIClient.h"
#import "Album.h"
#import "AlbumArtManager.h"
#import "AlbumViewController.h"
#import "ExploreViewController.h"
#import "FXBlurView.h"
#import "ExploreCollectionView.h"
#import "ExploreCollectionViewCell.h"
#import "Analytics.h"

@interface ExploreViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableExplore;
@property (strong, nonatomic) NSArray *titles;
@property (strong, nonatomic) NSArray *albums;
@property (nonatomic) NSInteger currentRow;

@end

@implementation ExploreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Explore"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"Explore"]];
        
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self tableExplore] setBackgroundColor:[UIColor whiteColor]];
    [[self tableExplore] setSeparatorInset:UIEdgeInsetsMake(0, 20, 0, 0)];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[BollywoodAPIClient shared] fetchExploreAlbumsWithBlock:^(NSArray *titles, NSArray *albums) {
        [self setTitles:titles];
        [self setAlbums:albums];
        
        [[self tableExplore] reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Analytics shared] tagScreen:@"Explore"];
}

#pragma mark - Table Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self titles] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 165;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ExploreTableCell";
    static NSString *cellNib = @"ExploreTableCellView";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:cellNib owner:self options:nil];
        cell = [nibs firstObject];
    }
    
    UILabel *lblHeader = (UILabel *)[cell viewWithTag:100];
    [lblHeader setText:[[self titles] objectAtIndex:indexPath.row]];

    ExploreCollectionView *items = (ExploreCollectionView *)[cell viewWithTag:101];
    
    [items setDelegate:self];
    [items setDataSource:self];
    
    [items setBelongsToRow:indexPath.row];

    return cell;
}

#pragma mark - Collection Data Source

- (NSInteger)collectionView:(ExploreCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[self albums] objectAtIndex:[collectionView belongsToRow]] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(90, 130);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 20.0;
}

- (ExploreCollectionViewCell *)collectionView:(ExploreCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ExploreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ExploreCollectionCell" forIndexPath:indexPath];
    
    NSArray *albums = [[self albums] objectAtIndex:[collectionView belongsToRow]];
    Album *album = [albums objectAtIndex:indexPath.row];
    
    [cell setTitleText:[album name]];
    [cell setImageFromAlbum:album];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(ExploreCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *albums = [[self albums] objectAtIndex:[collectionView belongsToRow]];
    AlbumViewController *albumView = [[AlbumViewController alloc] initWithAlbum:[albums objectAtIndex:indexPath.row] Origin:@"Explore"];
    [[self navigationController] pushViewController:albumView animated:YES];
}

@end
