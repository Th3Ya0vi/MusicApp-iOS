//
//  AlbumArtRequest.h
//  Music
//
//  Created by Tushar Soni on 12/15/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"
#import "Album.h"

enum AlbumArtSize {BIG, SMALL};

@interface AlbumArtRequest : NSObject

- (instancetype)initWithAlbum: (Album *)album Size: (enum AlbumArtSize)size CompletionBlock: (void(^)(UIImage *image, BOOL didSucceed))block;
- (void)start;
- (void)cancel;

@property (strong, nonatomic) NSString *senderID;
@property (strong, nonatomic) Album *album;
@property (nonatomic) enum AlbumArtSize size;
@property (strong, nonatomic) void(^completionBlock)(UIImage *image, BOOL didSucceed);
@property (strong, nonatomic) AFHTTPRequestOperation *requestOperation;

@end
