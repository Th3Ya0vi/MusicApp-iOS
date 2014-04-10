//
//  AlbumArtManager.m
//  Music
//
//  Created by Tushar Soni on 12/15/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AlbumArtManager.h"

@implementation AlbumArtManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.requests = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (instancetype)shared
{
    static AlbumArtManager *manager;
    
    if (manager == nil)
        manager = [[AlbumArtManager alloc] init];
    
    return manager;
}

- (void)fetchAlbumArtForAlbum: (Album *)album Size:(enum AlbumArtSize)size From: (NSString *)senderid CompletionBlock: (void(^)(UIImage *image, BOOL didSucceed))block
{
    UIImage *image = [self existingImageForAlbum:album Size:size];
    if (image)
        block(image, YES);
    else
    {
        AlbumArtRequest *request = [[AlbumArtRequest alloc] initWithAlbum:album Size:size CompletionBlock:block];
        [request setSenderID:senderid];
        [request start];
        [[self requests] addObject:request];
    }
}

- (UIImage *)existingImageForAlbum: (Album *)album Size: (enum AlbumArtSize)size
{
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%d.jpg", [album albumid], size]];
    
    UIImage *existing = ([[NSFileManager defaultManager] fileExistsAtPath:path]) ? [UIImage imageWithContentsOfFile:path] : nil;
    
    if (existing == nil && size == SMALL)
        return [self existingImageForAlbum:album Size:BIG];
    
    return existing;
}

- (void)cancelFromSender: (NSString *)senderid
{
    [[self requests] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AlbumArtRequest *request = (AlbumArtRequest *)obj;
        if ([[request senderID] isEqualToString:senderid])
            [request cancel];
    }];
}

- (void)deleteAllSavedImages
{
    NSArray *images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] error:nil];
    
    [images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj pathExtension] isEqualToString:@"jpg"])
        {
            NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
            NSString *filePath = [cacheDir stringByAppendingPathComponent:obj];
            [[NSFileManager defaultManager] removeItemAtPath:[NSURL URLWithString:filePath] error:nil];
        }
    }];
}
@end
