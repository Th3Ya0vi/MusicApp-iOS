//
//  AppDelegate.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AppDelegate.h"
#import "LoadingViewController.h"
#import "Activity.h"
#import "Player.h"
#import "Playlist.h"
#import "BollywoodAPIClient.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "LocalyticsSession.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LoadingViewController *loading = [[LoadingViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = loading;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    // [[LocalyticsSession shared] close];
    // [[LocalyticsSession shared] upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if ([[Player shared] currentStatus] != PLAYING && [[Player shared] currentStatus] != LOADING)
    {
        [[LocalyticsSession shared] close];
        [[LocalyticsSession shared] upload];
    }
    
    [[BollywoodAPIClient shared] postUserActivity];
    [[User currentUser] save];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didCrash"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[LocalyticsSession shared] LocalyticsSession:@LOCALYTICS_APP_KEY];
    [[LocalyticsSession shared] setLoggingEnabled:YES];
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidBecomeActive" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
    
    [[Player shared] stop];
    [[User currentUser] save];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl)
    {
        switch (receivedEvent.subtype)
        {
            case UIEventSubtypeRemoteControlPause:
                [[Player shared] togglePlayPause];
                [[LocalyticsSession shared] close];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [[Player shared] togglePlayPause];
                [[LocalyticsSession shared] resume];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [[Player shared] loadSong:previousSongInPlaylist ShouldPlay:isPlayerPlaying];
                [[LocalyticsSession shared] tagEvent:@"Song Change" attributes:[NSDictionary dictionaryWithObject:@"Remote Control" forKey:@"How"]];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [[Player shared] loadSong:nextSongInPlaylist ShouldPlay:isPlayerPlaying];
                [[LocalyticsSession shared] tagEvent:@"Song Change" attributes:[NSDictionary dictionaryWithObject:@"Remote Control" forKey:@"How"]];
                break;
            default:
                break;
        }
    }
}


@end
