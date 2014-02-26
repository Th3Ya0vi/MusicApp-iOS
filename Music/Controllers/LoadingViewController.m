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
#import "PlayerViewController.h"
#import "BollywoodAPIClient.h"
#import "Playlist.h"
#import "AlbumArtManager.h"
#import "Analytics.h"
#import "CrashResolverViewController.h"
#import "AlbumViewController.h"
#import "AFNetworkReachabilityManager.h"

@interface LoadingViewController ()

@end

@implementation LoadingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[UINavigationBar appearance] setTintColor:[UIColor darkGrayColor]];
        [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Futura" size:18.0], NSFontAttributeName, nil]];
        [self configureiRate];
        [self setupCache];
        [self clearCacheIfNecessary];
    }
    return self;
}

#pragma mark - View

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([self didAppCrashLastTime])
    {
        CrashResolverViewController *crashResolver = [[CrashResolverViewController alloc] initWithNibName:nil bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:crashResolver];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if ([User currentUser] == nil)
    {
        [[BollywoodAPIClient shared] createNewUserWithSuccess:^(User *user) {
            [self loadMainView];
        } Failure:^{
            [[[UIAlertView alloc] initWithTitle:@"Can't Connect" message:@"Please make sure you are connected to the internet" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        }];
    }
    else if([[NSUserDefaults standardUserDefaults] objectForKey:@"NotificationInfo"] != nil)
    {
        if ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"NotificationInfo"] objectForKey:@"Type"] isEqualToString:@"Release"])
        {
            NSString *albumid = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NotificationInfo"] objectForKey:@"AlbumID"];
            [[BollywoodAPIClient shared] fetchAlbumWithAlbumID:albumid CompletionBlock:^(Album *album) {
                
                AlbumViewController *albumView = [[AlbumViewController alloc] initWithAlbum:album Origin:@"Notification"];
                UINavigationController *navControllerForAlbumView = [[UINavigationController alloc] initWithRootViewController:albumView];
                
                [self presentViewController:navControllerForAlbumView animated:YES completion:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NotificationInfo"];
            }];
        }
        else
            [self loadMainView];
    }
    else
        [self loadMainView];
}

- (void)loadMainView
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    
    UITabBarController *tabbar = [[UITabBarController alloc] init];
    [[tabbar tabBar] setTintColor:[UIColor darkGrayColor]];
    
    PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithNibName:nil bundle:nil];
    
    SearchViewController *searchViewController = [[SearchViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *uiNavControllerForSearch = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *uiNavControllerForDownloads = [[UINavigationController alloc] initWithRootViewController:downloadsViewController];
    
    ExploreViewController *exploreViewController = [[ExploreViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *uiNavControllerForExplore = [[UINavigationController alloc] initWithRootViewController:exploreViewController];
    
    tabbar.viewControllers = [NSArray arrayWithObjects:playerViewController,uiNavControllerForExplore,uiNavControllerForSearch,uiNavControllerForDownloads,nil];
    
    [self presentViewController:tabbar animated:NO completion:^{
        if ([[Playlist shared] count] == 0)
            [tabbar setSelectedIndex:1];
    }];
}

#pragma mark - iRate methods

- (void)configureiRate
{
    [[iRate sharedInstance] setVerboseLogging:NO];
    [iRate sharedInstance].daysUntilPrompt = 3;
    [iRate sharedInstance].usesUntilPrompt = 5;
}

#pragma mark - iRate Delegate

- (void)iRateUserDidAttemptToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Type" forKey:@"Attempt"]];
}

- (void)iRateUserDidDeclineToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Type" forKey:@"Decline"]];
}

- (void)iRateUserDidRequestReminderToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Type" forKey:@"Remind"]];
}

#pragma mark - Cache methods

- (void)setupCache
{
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:20 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
}

- (void)clearCacheIfNecessary
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"resetCache"] == YES)
    {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [[AlbumArtManager shared] deleteAllSavedImages];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"resetCache"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"Cleared Cache");
    }
}

#pragma mark - Crash Resolver

- (BOOL)didAppCrashLastTime
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    if ([userDef boolForKey:@"didCrash"] == YES) return YES;
    
    [userDef setBool:YES forKey:@"didCrash"];
    [userDef synchronize];

    return NO;
}

@end
