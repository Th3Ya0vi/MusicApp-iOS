//
//  User.m
//  Music
//
//  Created by Tushar Soni on 11/25/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "User.h"
#import "Activity.h"
#import "AFHTTPRequestOperationManager.h"
#import "Flurry.h"
#import "BollywoodAPIClient.h"

@implementation User

+ (instancetype) currentUser
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    if ([userDef objectForKey:@"userid"] == nil)
        return nil;
    
    static User *user;
    if (user==nil)
    {
        user = [[User alloc] init];
        user.userid = [[userDef objectForKey:@"userid"] integerValue];
        user.currentPlaylistIndex = [userDef integerForKey:@"currentPlaylistIndex"];
        user.activity = [[NSKeyedUnarchiver unarchiveObjectWithData:[userDef dataForKey:@"activity"]] mutableCopy];
        user.playlist = [[NSKeyedUnarchiver unarchiveObjectWithData:[userDef dataForKey:@"playlist"]] mutableCopy];
        user.downloads = [[NSKeyedUnarchiver unarchiveObjectWithData:[userDef dataForKey:@"downloads"]] mutableCopy];
        
        [Flurry setUserID:[NSString stringWithFormat:@"%d", [user userid]]];
    }
    return user;
    
}

- (void) save
{
    NSData *playlistData = [NSKeyedArchiver archivedDataWithRootObject:[self playlist]];
    NSData *activityData = [NSKeyedArchiver archivedDataWithRootObject:[self activity]];
    NSData *downloadedData = [NSKeyedArchiver archivedDataWithRootObject:[self downloads]];
    
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSString stringWithFormat:@" %@", [userDef objectForKey:@"userid"]] forKey:@"useridSettings"];
    [userDef setObject:playlistData forKey:@"playlist"];
    [userDef setObject:activityData forKey:@"activity"];
    [userDef setObject:downloadedData forKey:@"downloads"];
    [userDef setInteger:self.currentPlaylistIndex forKey:@"currentPlaylistIndex"];
    [userDef synchronize];
}

#define updateSongData  \
doNeedToUpdate = YES; \
[[BollywoodAPIClient shared] fetchSongWithSongID:[obj songid] CompletionBlock:^(Song *song) { \
    [obj setCloudMp3Path:[song cloudMp3Path]]; \
    totalChecked++; \
    if (totalChecked == [[self playlist] count] + [[self downloads] count]) \
        completionBlock(); \
}];

- (void)updateStoredSongDataIfNecessaryWithCompletionBlock: (void(^)(void))completionBlock
{
    __block NSUInteger totalChecked = 0;
    __block BOOL doNeedToUpdate = NO;
    
    [[self downloads] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj cloudMp3Path] == nil)
        {
            updateSongData
        }
    }];
    
    [[self playlist] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj cloudMp3Path] == nil)
        {
            updateSongData
        }
    }];
    
    if (doNeedToUpdate == NO)
        completionBlock();
}

@end
