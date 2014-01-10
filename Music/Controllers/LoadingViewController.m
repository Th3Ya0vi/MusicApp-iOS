//
//  LoadingViewController.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "LoadingViewController.h"
#import "User.h"
#import "SearchViewController.h"
#import "DownloadsViewController.h"
#import "ExploreViewController.h"
#import "Activity.h"
#import "PlayerViewController.h"
#import "BollywoodAPIClient.h"

@interface LoadingViewController ()

@end

@implementation LoadingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

#pragma mark - View

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([User currentUser] == nil)
    {
        [[BollywoodAPIClient shared] createNewUserWithSuccess:^(User *user) {
            [self loadMainView];
        } Failure:^{
            [[[UIAlertView alloc] initWithTitle:@"Can't Connect" message:@"Please make sure you are connected to the internet" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        }];
    }
    else
    {
        [[BollywoodAPIClient shared] postUserActivity];
        [self loadMainView];
    }

}

- (void)loadMainView
{
    UITabBarController *tabbar = [[UITabBarController alloc] init];
    [[tabbar tabBar] setTintColor:[UIColor darkGrayColor]];
    
    PlayerViewController *playlerViewController = [[PlayerViewController alloc] initWithNibName:@"PlayerView" bundle:nil];
    
    SearchViewController *searchViewController = [[SearchViewController alloc] initWithNibName:@"SearchView" bundle:nil];
    UINavigationController *uiNavControllerForSearch = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithNibName:@"DownloadsView" bundle:nil];
    UINavigationController *uiNavControllerForDownloads = [[UINavigationController alloc] initWithRootViewController:downloadsViewController];
    
    ExploreViewController *exploreViewController = [[ExploreViewController alloc] initWithNibName:@"ExploreView" bundle:nil];
    UINavigationController *uiNavControllerForExplore = [[UINavigationController alloc] initWithRootViewController:exploreViewController];
    
    tabbar.viewControllers = [NSArray arrayWithObjects:playlerViewController,uiNavControllerForExplore,uiNavControllerForSearch,uiNavControllerForDownloads,nil];
    
    [self presentViewController:tabbar animated:NO completion:nil];
}

@end
