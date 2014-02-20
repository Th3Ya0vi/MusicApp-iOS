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
#import "Flurry.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Flurry startSession:@FLURRY_APP_KEY];
    
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


@end
