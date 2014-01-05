//
//  Activity.h
//  Music
//
//  Created by Tushar Soni on 12/4/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"

enum Activity_Action {
    DOWNLOADED,
    DELETEDFROMDOWNLOADS,
    ADDEDTOPLAYLIST,
    DELETEDFROMPLAYLIST,
    STARTEDLISTENING,
    FINISHEDLISTENING,
    SHUFFLED,
    INCORRECTDATA
};

@interface Activity : NSObject <NSCoding, NSCopying>

- (id)initWithSong:(Song *)song action:(enum Activity_Action)action extra:(NSString *)extra;
+ (void)addWithSong:(Song *)song action:(enum Activity_Action)action extra:(NSString *)extra;
+ (void)addWithSong:(Song *)song action:(enum Activity_Action)action;

@property (strong, nonatomic) NSString *songid;
@property (nonatomic) NSInteger timestamp;
@property (nonatomic) enum Activity_Action action;
@property (strong, nonatomic) NSString *extra;

- (NSString *)description;
- (NSDictionary *)dictionary;
+ (NSString *)stringForAction: (enum Activity_Action) action;
+ (void)postActivity;

@end
