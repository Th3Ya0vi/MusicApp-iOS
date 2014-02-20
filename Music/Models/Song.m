//
//  Song.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Song.h"
#import "Album.h"
#import "User.h"
#import "Player.h"
#import "Activity.h"
#import "BollywoodAPIClient.h"
#import "AFURLSessionManager.h"

@implementation Song

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    
    if (self)
    {
        self.songid = [json objectForKey:@"SongID"];
        self.albumid = [json objectForKey:@"AlbumID"];
        self.name = [json objectForKey:@"Name"];
        self.singers = [json objectForKey:@"Singers"];
        self.cloudMp3Path = [NSURL URLWithString:[json objectForKey:@"Mp3"]];
        
        if ([json objectForKey:@"Album"] != nil)
            self.album = [[Album alloc] initWithJSON:[json objectForKey:@"Album"]];
    }
    
    return self;
}

+ (NSArray *) songsWithJSONArray: (NSArray *)jsonArray
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[jsonArray count]];
    
    [jsonArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [tempArray addObject:[[Song alloc] initWithJSON:obj]];
    }];

    return tempArray;
}

- (BOOL) isEqual:(id)object
{
    return [[self songid] isEqual:[object songid]];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.songid = [aDecoder decodeObjectForKey:@"songid"];
        self.albumid = [aDecoder decodeObjectForKey:@"albumid"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.singers = [aDecoder decodeObjectForKey:@"singers"];
        self.cloudMp3Path = [aDecoder decodeObjectForKey:@"cloudMp3"];
        
        if ([aDecoder containsValueForKey:@"album"])
            self.album = [aDecoder decodeObjectForKey:@"album"];
    
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Song *copy = [[Song alloc] init];
    
    if (copy)
    {
        [copy setSongid:self.songid];
        [copy setAlbumid:self.albumid];
        [copy setName:[self.name copyWithZone:zone]];
        [copy setSingers:[self.singers copyWithZone:zone]];
        [copy setCloudMp3Path:[[self cloudMp3Path] copyWithZone:zone]];
        
        if ([self album])
            [copy setAlbum:[self.album copyWithZone:zone]];
    }
    
    return copy;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songid forKey:@"songid"];
    [aCoder encodeObject:self.albumid forKey:@"albumid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.singers forKey:@"singers"];
    [aCoder encodeObject:self.cloudMp3Path forKey:@"cloudMp3"];
    
    if ([self album])
        [aCoder encodeObject:self.album forKey:@"album"];
}

- (enum SongAvailability)availability
{
    if (_availability == DOWNLOADING)
        return _availability;
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[[self localMp3Path] path] isDirectory:NO])
        return LOCAL;
    else if([[NSString stringWithFormat:@"%@", [self cloudMp3Path]] isEqualToString:@""])
        return UNAVAILABLE;
    else
        return CLOUD;
}

- (NSURL *)mp3
{
    return ([self availability] == LOCAL) ? [self localMp3Path] : [self cloudMp3Path];
}

- (NSURL *)localMp3Path
{
    NSURL *documentDir = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject]];
    return [documentDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", [self songid]]];
}

- (AVPlayerItem *)getPlayerItem
{
    if (_playerItem == nil || [self availability] == LOCAL)
        [self setPlayerItem:[[AVPlayerItem alloc] initWithURL:[self mp3]]];
    else
        [_playerItem seekToTime:kCMTimeZero];
    
    return _playerItem;
}

@end
