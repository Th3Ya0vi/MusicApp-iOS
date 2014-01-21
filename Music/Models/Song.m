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
#import "Activity.h"
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
        self.mp3 = [NSURL URLWithString:[json objectForKey:@"Mp3"]];
        
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

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.songid = [aDecoder decodeObjectForKey:@"songid"];
        self.albumid = [aDecoder decodeObjectForKey:@"albumid"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.singers = [aDecoder decodeObjectForKey:@"singers"];
        self.mp3 = [aDecoder decodeObjectForKey:@"mp3"];
        
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
        [copy setMp3:[self.mp3 copyWithZone:zone]];
        
        if ([self album])
            [copy setAlbum:[self.album copyWithZone:zone]];
    }
    
    return copy;
}

+ (instancetype) currentSongInPlaylist
{
    if ([[User currentUser] currentPlaylistIndex] >= [[[User currentUser] playlist] count])
        [[User currentUser] setCurrentPlaylistIndex:0];
    if ([[[User currentUser] playlist] count] == 0)
        return nil;
    
    return [[[User currentUser] playlist] objectAtIndex:[[User currentUser] currentPlaylistIndex]];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.songid forKey:@"songid"];
    [aCoder encodeObject:self.albumid forKey:@"albumid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.singers forKey:@"singers"];
    [aCoder encodeObject:self.mp3 forKey:@"mp3"];
    
    if ([self album])
        [aCoder encodeObject:self.album forKey:@"album"];
}

- (void)startDownloadWithOrigin: (NSString *)origin
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    
    self.availability = DOWNLOADING;
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[self mp3]] progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
    {
        return [self localMp3Path];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
    {
        if (error)
        {
            NSLog(@"Error downloading song: %@", [error localizedDescription]);
            self.availability = CLOUD;
            [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([[(Song *)obj songid] isEqualToString:[self songid]])
                    [[[User currentUser] downloads] removeObjectAtIndex:idx];
            }];
        }
        else
        {
            [Activity addWithSong:self action:DOWNLOADED extra:origin];
            self.availability = LOCAL;
            [[self localMp3Path] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadedSong" object:self];
    }];
    
    
    __block Song *weakCopy = self;
    [manager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)
    {
        float prog = (float)totalBytesWritten/totalBytesExpectedToWrite;
        
        NSMutableDictionary *progress = [[NSMutableDictionary alloc] init];
        progress[@"Song"] = weakCopy;
        progress[@"Progress"] = [NSNumber numberWithFloat:prog];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadingSong" object:progress];
    }];
    
    [[[User currentUser] downloads] addObject:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartDownloadingSong" object:nil];
    
    [downloadTask resume];
}

- (enum SongAvailability)availability
{
    if (_availability == DOWNLOADING)
        return _availability;
    else if([[NSString stringWithFormat:@"%@", _mp3] isEqualToString:@""])
        return UNAVAILABLE;
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[[self localMp3Path] path] isDirectory:NO])
        return LOCAL;
    else
        return CLOUD;
}

- (NSURL *)mp3
{
    return ([self availability] == LOCAL) ? [self localMp3Path] : _mp3;
}

- (NSURL *)localMp3Path
{
    NSURL *documentDir = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject]];
    return [documentDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", [self songid]]];
}

- (BOOL) deleteLocalFile
{
    if ([self availability] != LOCAL)
        return NO;
    
    [[NSFileManager defaultManager] removeItemAtPath:[[self localMp3Path] path] error:nil];
    [[[User currentUser] downloads] removeObject:self];
    [Activity addWithSong:self action:DELETEDFROMDOWNLOADS];
    return YES;
}

- (void)addToPlaylistAndPostNotificationWithOrigin: (NSString *)origin
{
    Song *copy = [self copy];
    [[[User currentUser] playlist] addObject:copy];
    [Activity addWithSong:copy action:ADDEDTOPLAYLIST extra:origin];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaylistUpdated" object:nil];
}

- (void)removeFromPlaylistAndPostNotification
{
    [Activity addWithSong:self action:DELETEDFROMPLAYLIST];
    [[[User currentUser] playlist] removeObjectIdenticalTo:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlaylistUpdated" object:nil];
}

@end
