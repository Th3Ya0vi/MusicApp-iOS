//
//  User.m
//  Music
//
//  Created by Tushar Soni on 11/25/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "User.h"
#import "AFHTTPRequestOperationManager.h"
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
        user.playlist = [[NSKeyedUnarchiver unarchiveObjectWithData:[userDef dataForKey:@"playlist"]] mutableCopy];
        user.downloads = [[NSKeyedUnarchiver unarchiveObjectWithData:[userDef dataForKey:@"downloads"]] mutableCopy];
        
        [user removeOldData];
    }
    return user;
    
}

- (void) save
{
    NSData *playlistData = [NSKeyedArchiver archivedDataWithRootObject:[self playlist]];
    NSData *downloadedData = [NSKeyedArchiver archivedDataWithRootObject:[self downloads]];
    
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSString stringWithFormat:@" %@", [userDef objectForKey:@"userid"]] forKey:@"useridSettings"];
    [userDef setObject:playlistData forKey:@"playlist"];
    [userDef setObject:downloadedData forKey:@"downloads"];
    [userDef setInteger:self.currentPlaylistIndex forKey:@"currentPlaylistIndex"];
    [userDef synchronize];
}

- (void)removeOldData
{
    /**Remove songs from playlist with no cloudMp3Path**/
    NSMutableArray *oldSongs = [[NSMutableArray alloc] init];
    [[self playlist] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj cloudMp3Path] == nil)
        {
            [oldSongs addObject:obj];
        }
    }];
    [[self playlist] removeObjectsInArray:oldSongs];
    /**----------------------------------------------**/
}

@end
