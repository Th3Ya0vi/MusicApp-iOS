//
//  AlbumArtManager.h
//  Music
//
//  Created by Tushar Soni on 12/15/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"
#import "AlbumArtRequest.h"
#import "Album.h"

@interface AlbumArtManager : NSObject

@property (strong, nonatomic) NSMutableArray *requests;


+ (instancetype)shared;
- (void)fetchAlbumArtForAlbum: (Album *)album Size:(enum AlbumArtSize)size From: (NSString *)senderid CompletionBlock: (void(^)(UIImage *image, BOOL didSucceed))block;
- (UIImage *)existingImageForAlbum: (Album *)album Size: (enum AlbumArtSize)size;
- (void)cancelFromSender: (NSString *)senderid;
- (void)deleteAllSavedImages;

@end
