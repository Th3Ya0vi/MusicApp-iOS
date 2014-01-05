//
//  ExploreViewController.m
//  Music
//
//  Created by Tushar Soni on 12/18/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Explore.h"
#import "Album.h"
#import "AlbumArtManager.h"
#import "AlbumViewController.h"
#import "ExploreViewController.h"
#import "FXBlurView.h"

#define ITEM_SIZE   150

@interface ExploreViewController ()

@property (strong, nonatomic) Explore *explore;
@property (weak, nonatomic) IBOutlet UITableView *tableExplore;

@end

@implementation ExploreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Explore"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"Explore"]];
        
        self.explore = [[Explore alloc] init];
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[self explore] fetchWithBlock:^
     {
         [[self tableExplore] reloadData];
    }];
}

#pragma mark - Table Data Source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self explore] titles] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[self explore] titles] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ExploreCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UICollectionView *items = (UICollectionView *)[cell viewWithTag:100];
    if (items)
        [items removeFromSuperview];
    
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    [flow setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    items = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 150) collectionViewLayout:flow];
    
    [items setTag:100];
    
    [items setBackgroundColor:[UIColor clearColor]];
    
    [items registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ImageGridCell"];
    
    [items setDelegate:self];
    [items setDataSource:self];
    
    [cell addSubview:items];

    
    return cell;
}

#pragma mark - Collection Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[[self explore] albums] objectAtIndex:section] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(ITEM_SIZE, ITEM_SIZE);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageGridCell" forIndexPath:indexPath];
    
    UIImageView *albumArt = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ITEM_SIZE, ITEM_SIZE)];
    [albumArt setBackgroundColor:[UIColor clearColor]];
    [albumArt setImage:nil];
    [cell addSubview:albumArt];
    
    NSArray *albums = [[[self explore] albums] objectAtIndex:indexPath.section];
    
    Album *album = [albums objectAtIndex:indexPath.row];
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:album Size:SMALL From:@"ExploreView" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
        [albumArt setImage:image];
    }];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *albums = [[[self explore] albums] objectAtIndex:indexPath.section];
    
    AlbumViewController *albumView = [[AlbumViewController alloc] initWithNibName:@"AlbumView" bundle:nil];
    UINavigationController *navControllerForAlbumView = [[UINavigationController alloc] initWithRootViewController:albumView];
    
    [albumView setOrigin:@"Explore"];
    [albumView setAlbum:[albums objectAtIndex:indexPath.row]];
    
    [self presentViewController:navControllerForAlbumView animated:YES completion:nil];
}

@end
