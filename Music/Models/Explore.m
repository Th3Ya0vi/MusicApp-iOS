//
//  Explore.m
//  Music
//
//  Created by Tushar Soni on 12/8/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Explore.h"
#import "AFHTTPRequestOperationManager.h"
#import "Song.h"
#import "Album.h"

@interface Explore ()

@property (strong, nonatomic) AFHTTPRequestOperation *requestOperation;

@end

@implementation Explore

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.albums = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)cancel
{
    [[self requestOperation] cancel];
}

- (void)fetchWithBlock:(void (^)(void))block
{
    [self cancel];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSString *url = [NSString stringWithFormat:@"%s/explore", BASE_URL];
    
    self.requestOperation = [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *response = (NSDictionary *)responseObject;
        
        [self setTitles:[response objectForKey:@"Titles"]];
        
        [[self titles] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

            NSString *title = (NSString *)obj;
            NSArray *tempAlbums = [[response objectForKey:@"Albums"] objectForKey:title];
            NSMutableArray *albumsToGo = [[NSMutableArray alloc] init];
            
            [tempAlbums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [albumsToGo addObject:[[Album alloc] initWithJSON:obj]];
            }];
            
            [[self albums] addObject:albumsToGo];
        }];

        block();
        
    } failure:^(AFHTTPRequestOperation *operation , NSError *error)
    {
        NSLog(@"Failed to fetch explore data.");
    }];
}

@end
