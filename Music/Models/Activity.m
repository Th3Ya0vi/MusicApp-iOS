//
//  Activity.m
//  Music
//
//  Created by Tushar Soni on 12/4/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Activity.h"
#import "User.h"

@implementation Activity

- (id)initWithSong:(Song *)song action:(enum Activity_Action)action extra:(NSString *)extra
{
    self = [super init];
    
    if (self)
    {
        self.songid = [song songid];
        self.action = action;
        self.extra = extra;
        self.timestamp = [[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] integerValue];
    }
    
    return self;
}

+ (void)addWithSong:(Song *)song action:(enum Activity_Action)action extra:(NSString *)extra
{
    NSLog(@"Activity: %@ - %@ - %@", [song name], [Activity stringForAction:action], extra);
    Activity *activity = [[Activity alloc] initWithSong:song action:action extra:extra];
    [[[User currentUser] activity] addObject:activity];
}

+ (void)addWithSong:(Song *)song action:(enum Activity_Action)action
{
    [Activity addWithSong:song action:action extra:@""];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    Activity *copy = [[Activity alloc] init];
    
    if (copy)
    {
        [copy setSongid:[[self songid] copyWithZone:zone]];
        [copy setTimestamp:[self timestamp]];
        [copy setAction:[self action]];
        [copy setExtra:[[self extra] copyWithZone:zone]];
    }
    
    return copy;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self  = [super init];
    
    if (self)
    {
        self.songid = [aDecoder decodeObjectForKey:@"songid"];
        self.timestamp = [aDecoder decodeIntegerForKey:@"timestamp"];
        self.action = [aDecoder decodeIntegerForKey:@"action"];
        self.extra = [aDecoder decodeObjectForKey:@"extra"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self songid] forKey:@"songid"];
    [aCoder encodeInteger:[self timestamp] forKey:@"timestamp"];
    [aCoder encodeInteger:[self action] forKey:@"action"];
    [aCoder encodeObject:[self extra] forKey:@"extra"];
}

+ (NSString *)stringForAction: (enum Activity_Action) action
{
    switch (action)
    {
        case DOWNLOADED:
            return @"Downloaded";
            break;
        case ADDEDTOPLAYLIST:
            return @"AddedToPlaylist";
            break;
        case FINISHEDLISTENING:
            return @"FinishedListening";
            break;
        case INCORRECTDATA:
            return @"IncorrectData";
            break;
    }
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    dict[@"SongID"] = [self songid];
    dict[@"Timestamp"] = [NSNumber numberWithInteger:[self timestamp]];
    dict[@"Action"] = [Activity stringForAction:[self action]];
    dict[@"Extra"] = [self extra];
    
    return [dict copy];
}

@end
