//
//  AlbumArtRequest.m
//  Music
//
//  Created by Tushar Soni on 12/15/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AlbumArtRequest.h"
#import "AlbumArtManager.h"

@implementation AlbumArtRequest

- (instancetype)initWithAlbum: (Album *)album Size: (enum AlbumArtSize)size CompletionBlock: (void(^)(UIImage *image, BOOL didSucceed))block;
{
    self = [super init];
    
    if (self)
    {
        self.album = album;
        self.size = size;
        self.completionBlock = block;
    }
    
    return self;
}

- (void)start
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];

    NSString *url = ([self size] == BIG) ? [[self album] albumArtBigURL] : [[self album] albumArtSmallURL];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
    
    self.requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        UIImage *image = (UIImage *)responseObject;
        
        NSData *data = UIImageJPEGRepresentation(image, 0);
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@_%d.jpg", [[self album] provider], [[self album] albumid], [self size]]];
        [data writeToFile:path atomically:YES];
        
        self.completionBlock(image, YES);
        [[[AlbumArtManager shared] requests] removeObject:self];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        NSLog(@"Failed to fetch album art: %@", [error localizedDescription]);
        
        if ([self size] == SMALL)
        {
            self.completionBlock([UIImage imageNamed:@"DefaultAlbumArtDark"], NO);
            [[[AlbumArtManager shared] requests] removeObject:self];
        }
        else
        {
            [self setSize:SMALL];
            [self start];
        }
    }];
    
    [[self requestOperation] start];
}

- (void)cancel
{
    [[self requestOperation] cancel];
    [[[AlbumArtManager shared] requests] removeObject:self];
}

@end
