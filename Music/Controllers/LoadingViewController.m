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
#import "Playlist.h"
#import "AlbumArtManager.h"
#import "LocalyticsSession.h"
#import "CrashResolverViewController.h"

@interface LoadingViewController ()

@end

@implementation LoadingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
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
    else
    {
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
}

- (void)loadMainView
{
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

- (void)iRateDidPromptForRating
{
    [self logiRateEventWithEvent:@"iRate Prompt"];
}

- (void)iRateUserDidAttemptToRateApp
{
    [self logiRateEventWithEvent:@"iRate Attempt"];
}

- (void)iRateUserDidDeclineToRateApp
{
    [self logiRateEventWithEvent:@"iRate Decline"];
}

- (void)iRateUserDidRequestReminderToRateApp
{
    [self logiRateEventWithEvent:@"iRate Remind"];
}

#pragma mark - iRate Delegate Helper Method(s)

- (void)logiRateEventWithEvent: (NSString *)event
{
    [[LocalyticsSession shared] tagEvent:event attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[[iRate sharedInstance] usesCount]] forKey:@"Use Count"]];
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
    
    if ([userDef boolForKey:@"didCrash"] == YES)
        return YES;
    
    [userDef setBool:YES forKey:@"didCrash"];
    [userDef synchronize];
    
    return NO;
}

@end
