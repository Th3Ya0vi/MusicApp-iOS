//
//  User.h
//  Music
//
//  Created by Tushar Soni on 11/25/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"

@interface User : NSObject

@property (nonatomic) NSInteger userid;
//@property (strong, nonatomic) NSMutableArray *activity;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong, nonatomic) NSMutableArray *downloads;
@property (nonatomic) NSInteger currentPlaylistIndex;
@property (nonatomic) BOOL hasSentPushTokenToServer;

+ (instancetype) currentUser;
- (void)save;

@end
