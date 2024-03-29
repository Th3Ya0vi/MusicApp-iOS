//
//  AppDelegate.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AppDelegate.h"
#import "LoadingViewController.h"
#import "Player.h"
#import "Playlist.h"
#import "BollywoodAPIClient.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "Analytics.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:CRASHLYTICS_API_KEY];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [self showLoadingScreen];
    
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
    

    [[User currentUser] save];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didCrash"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[Analytics shared] saveData];
    [[Analytics shared] post];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [self showLoadingScreen];
    
    [[Analytics shared] post];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidBecomeActive" object:nil];
    
    [[Analytics shared] post];
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

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"haveSavedDeviceToken"] == NO)
    {
        [[Analytics shared] setPushToken:deviceToken];
        [[Analytics shared] logEventWithName:EVENT_DEVICE_TOKEN Attributes:[NSDictionary dictionaryWithObject:@"Yes" forKey:@"Success"]];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"haveSavedDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [[Analytics shared] logEventWithName:EVENT_DEVICE_TOKEN Attributes:[NSDictionary dictionaryWithObject:@"No" forKey:@"Success"]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:@"NotificationInfo"];
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
                if ([[Playlist shared] isCurrentSongFirst] == NO)
                {
                    [[Player shared] loadSong:previousSongAuto ShouldPlay:isPlayerPlaying];
                    [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Remote Control" forKey:@"How"]];
                }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                if ([[Playlist shared] isCurrentSongLast] == NO)
                {
                    [[Player shared] loadSong:nextSongAuto ShouldPlay:isPlayerPlaying];
                    [[Analytics shared] logEventWithName:EVENT_SONG_CHANGE Attributes:[NSDictionary dictionaryWithObject:@"Remote Control" forKey:@"How"]];
                }
                break;
            default:
                break;
        }
    }
}

- (void)showLoadingScreen
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LoadingViewController *loading = [[LoadingViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = loading;
    [self.window makeKeyAndVisible];
}

#pragma mark - iRate Delegate

- (void)iRateUserDidAttemptToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Attempt" forKey:@"Type"]];
}

- (void)iRateUserDidDeclineToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Decline" forKey:@"Type"]];
}

- (void)iRateUserDidRequestReminderToRateApp
{
    [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Remind" forKey:@"Type"]];
}

@end
