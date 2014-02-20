//
//  AppDelegate.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AppDelegate.h"
#import "LoadingViewController.h"
#import "User.h"
#import "AlbumArtManager.h"
#import "Activity.h"
#import "Player.h"
#import "Playlist.h"
#import "BollywoodAPIClient.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "Flurry.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([self didAppCrashLastTime])
        return NO;
    
    [self setupCache];
    [self clearCacheIfNecessary];
    [self configureiRate];
    [self configureFlurry];
    
    [Flurry startSession:@FLURRY_APP_KEY withOptions:launchOptions];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Futura" size:18.0], NSFontAttributeName, nil]];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

    [self setupAndShowLoading];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[BollywoodAPIClient shared] postUserActivity];
    [[User currentUser] save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidBecomeActive" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[Player shared] stop];
    [[User currentUser] save];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didCrash"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setupAndShowLoading
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    LoadingViewController *loading = [[LoadingViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = loading;
    
    [self.window makeKeyAndVisible];
}

- (void)configureiRate
{
    [[iRate sharedInstance] setVerboseLogging:NO];
    [iRate sharedInstance].daysUntilPrompt = 3;
    [iRate sharedInstance].usesUntilPrompt = 5;
}

- (void)setupCache
{
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:20 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
}

- (void)configureFlurry
{
    [Flurry setCrashReportingEnabled:YES];
#if DEBUG
    [Flurry setDebugLogEnabled:NO];
#endif
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

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl)
    {
        switch (receivedEvent.subtype)
        {
            case UIEventSubtypeRemoteControlPause:
                [[Player shared] togglePlayPause];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [[Player shared] togglePlayPause];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [[Player shared] loadSong:previousSongInPlaylist ShouldPlay:isPlayerPlaying];
                [Flurry logEvent:@"Song_Change" withParameters:[NSDictionary dictionaryWithObject:@"Remote_Control" forKey:@"How"]];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [[Player shared] loadSong:nextSongInPlaylist ShouldPlay:isPlayerPlaying];
                [Flurry logEvent:@"Song_Change" withParameters:[NSDictionary dictionaryWithObject:@"Remote_Control" forKey:@"How"]];
                break;
            default:
                break;
        }
    }
}

#pragma mark - iRate Delegate

- (void)iRateDidPromptForRating
{
    [self logiRateEventWithEvent:@"iRate_Prompt"];
}

- (void)iRateUserDidAttemptToRateApp
{
    [self logiRateEventWithEvent:@"iRate_Attempt"];
}

- (void)iRateUserDidDeclineToRateApp
{
    [self logiRateEventWithEvent:@"iRate_Decline"];
}

- (void)iRateUserDidRequestReminderToRateApp
{
    [self logiRateEventWithEvent:@"iRate_Remind"];
}

#pragma mark - iRate Delegate Helper Method(s)

- (void)logiRateEventWithEvent: (NSString *)event
{
    [Flurry logEvent:event withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[[iRate sharedInstance] usesCount]] forKey:@"Use_Count"]];
}

#pragma mark - Crash Resolver

- (BOOL)didAppCrashLastTime
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    if ([userDef boolForKey:@"didCrash"] == YES)
    {
        [[[UIAlertView alloc] initWithTitle:@"Is Filmi Crashing Repeatedly?" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"YES! Please fix it", nil] show];
        return YES;
    }
    
    [userDef setBool:YES forKey:@"didCrash"];
    [userDef synchronize];
    
    return NO;
}

- (void)resetAllSetings
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];

    [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
    
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"activity"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"playlist"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"downloads"];
    
    [userDef synchronize];
}

#pragma mark - Alert view delegate for crash resolver

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [self resetAllSetings];
        [[[UIAlertView alloc] initWithTitle:@"I've cleared all the data. EXIT the app and open it again to enjoy free Bollywood music!" message:@"If you are still having problems, email me at tusharsoni1205@gmail.com" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }
}

@end
