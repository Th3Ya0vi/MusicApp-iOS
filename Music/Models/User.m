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
        
    }
    return user;
    
}

+ (void) createUserWithBlock:(void (^)(User *user))block OnFailure: (void (^)(void))failureBlock
{    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager GET:[NSString stringWithFormat:@"%s/user/create", BASE_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *response = (NSDictionary *) responseObject;
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        [userDef setObject:[response objectForKey:@"UserID"] forKey:@"userid"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"playlist"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"activity"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"downloads"];
        [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
        [userDef synchronize];
        
        block([User currentUser]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Error creating user: %@", error);
        failureBlock();
    }];
}

- (void) save
{
    NSData *playlistData = [NSKeyedArchiver archivedDataWithRootObject:[self playlist]];
    NSData *activityData = [NSKeyedArchiver archivedDataWithRootObject:[self activity]];
    NSData *downloadedData = [NSKeyedArchiver archivedDataWithRootObject:[self downloads]];
    
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:playlistData forKey:@"playlist"];
    [userDef setObject:activityData forKey:@"activity"];
    [userDef setObject:downloadedData forKey:@"downloads"];
    [userDef setInteger:self.currentPlaylistIndex forKey:@"currentPlaylistIndex"];
    [userDef synchronize];
}

@end
