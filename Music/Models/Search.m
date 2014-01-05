//
//  Search.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Search.h"
#import "AlbumArtManager.h"
#import "Song.h"

@interface Search ()

@property (strong, nonatomic) AFHTTPRequestOperation *requestOperation;

@end

@implementation Search

- (id)initWithQuery:(NSString *) query SearchFor:(enum SearchScope)searchFor IsFinal: (BOOL) isFinal
{
    self = [super init];
    
    if (self)
    {
        self.query = query;
        self.searchFor = searchFor;
        self.didUserCancel = NO;
        self.isFinalSearch = isFinal;
    }
    
    return self;
}

- (void)searchWithBlock: (void (^)(NSString *query, enum SearchScope searchFor, NSArray *results))block OnFailure: (void (^)(void))failureBlock
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *path = ([self isFinalSearch]) ? @"/search" : @"/search/like";
    
    NSString *url = ([self searchFor] == SONG) ? [NSString stringWithFormat:@"%s%@/songs/%@", BASE_URL, path, [[self query] capitalizedString]] : [NSString stringWithFormat:@"%s%@/albums/%@", BASE_URL, path, [[self query] capitalizedString]];
    
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    self.requestOperation = [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSArray *response = (NSArray *)responseObject;
        NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:[response count]];
        
        for (int i=0;i<[response count];i++)
        {
            if (self.searchFor == SONG)
                [objects addObject:[[Song alloc] initWithJSON:[response objectAtIndex:i]]];
            else if(self.searchFor == ALBUM)
                [objects addObject:[[Album alloc] initWithJSON:[response objectAtIndex:i]]];
        }
        self.results = [objects copy];
        
        block(self.query, self.searchFor, self.results);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        if ([self didUserCancel] == NO)
        {
            NSLog(@"Error searching for songs,albums: %@", error);
            failureBlock();
        }
    }];
}

- (void)cancel
{
    [self setDidUserCancel: YES];
    [[self requestOperation] cancel];
}

@end
