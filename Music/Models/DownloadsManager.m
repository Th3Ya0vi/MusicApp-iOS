//
//  DownloadsManager.m
//  Music
//
//  Created by Tushar Soni on 2/10/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "DownloadsManager.h"
#import "Activity.h"
#import "AFURLSessionManager.h"
#import "Flurry.h"
#import "User.h"

@interface DownloadsManager ()

@property (weak, nonatomic) AFURLSessionManager *sessionManager;

@property (weak, nonatomic) Song *lastSong;
@property (weak, nonatomic) NSString *lastOrigin;
@property (nonatomic) BOOL lastSuccess;

@property (strong, nonatomic) NSMutableArray *downloadQueue;

@end

@implementation DownloadsManager

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        [self setSessionManager:[[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]]];
        [self setDownloadQueue:[[NSMutableArray alloc] init]];
        [self sanitize];
        
        [[self sessionManager] setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite)
         {
             [[self downloadQueue] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                 if ([obj objectForKey:@"DownloadTask"] == downloadTask)
                 {
                     float prog = (float)totalBytesWritten/totalBytesExpectedToWrite;
                     
                     NSMutableDictionary *progress = [[NSMutableDictionary alloc] init];
                     progress[@"Song"] = [obj objectForKey:@"Song"];
                     progress[@"Progress"] = [NSNumber numberWithFloat:prog];
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadingSong" object:progress];
                     *stop = YES;
                 }
             }];
         }];
    }
    
    return self;
}

+ (instancetype)shared
{
    static DownloadsManager *downloadsManager;
    
    if (downloadsManager == nil)
        downloadsManager = [[DownloadsManager alloc] init];
    
    return downloadsManager;
}

- (void)sanitize
{
    [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(Song *obj1, NSUInteger idx, BOOL *stop) {
        [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(Song *obj2, NSUInteger idx, BOOL *stop) {
            if ([obj1 isEqual:obj2] && obj1 != obj2)
                [[[User currentUser] downloads] removeObjectIdenticalTo:obj2];
        }];
    }];
}

- (NSInteger)currentNumberOfDownloadTasks
{
    return [[self downloadQueue] count];
}

- (void)downloadSong:(Song *)song Origin:(NSString *)origin
{
    [self deleteSongFromDownloads:song];
    [[[User currentUser] downloads] addObject:song];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[song mp3] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
    
    NSURLSessionDownloadTask *downloadTask = [[self sessionManager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [song localMp3Path];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        [self setLastOrigin:origin];
        [self setLastSong:song];
        [self setLastSuccess:error == nil];
        [self downloadDidComplete];
    }];
    
    [[self downloadQueue] addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:song, downloadTask, nil]
                                                                forKeys:[NSArray arrayWithObjects:@"Song", @"DownloadTask", nil]]];
    
    [song setAvailability:DOWNLOADING];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didStartDownloadingSong" object:nil];
    
    [downloadTask resume];
}

- (void)downloadDidComplete
{
    if ([self lastSuccess])
        [[[self lastSong] localMp3Path] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    
    [[self lastSong] setAvailability:([self lastSuccess]) ? LOCAL : CLOUD];
    [self addActivity];
    [self removeDownloadTaskWithSong:[self lastSong]];
    [self fireLocalNotification];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadedSong" object:nil];
}

- (void)addActivity
{
    if ([self lastSuccess])
        [Activity addWithSong:[self lastSong] action:DOWNLOADED extra:[self lastOrigin]];
    
    [Flurry logEvent:@"Song_Download"
      withParameters:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[[self lastSong] songid], [self lastOrigin], ([self lastSuccess]) ? @"Yes" : @"No", nil]
                                                 forKeys:[NSArray arrayWithObjects:@"SongID", @"Origin", @"Success", nil]]];
}

- (void)removeDownloadTaskWithSong: (Song *)song
{
    [[self downloadQueue] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([[obj objectForKey:@"Song"] isEqual:song])
            [[self downloadQueue] removeObjectAtIndex:idx];
    }];
}

- (void)fireLocalNotification
{
    UILocalNotification *notifyDownloaded = [[UILocalNotification alloc] init];
    [notifyDownloaded setHasAction:NO];
    [notifyDownloaded setSoundName:UILocalNotificationDefaultSoundName];
    
    if ([self lastSuccess])
        [notifyDownloaded setAlertBody:[NSString stringWithFormat:@"%@ has been downloaded", [[self lastSong] name]]];
    else
        [notifyDownloaded setAlertBody:[NSString stringWithFormat:@"Failed to download %@", [[self lastSong] name]]];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notifyDownloaded];
}

- (void)deleteSongFromDownloads: (Song *)song
{
    [[[User currentUser] downloads] enumerateObjectsUsingBlock:^(Song *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqual:song])
        {
            if ([obj availability] == LOCAL)
                [[NSFileManager defaultManager] removeItemAtURL:[obj localMp3Path] error:nil];
            [[[User currentUser] downloads] removeObjectAtIndex:idx];
        }
    }];
}

@end
