//
//  Search.h
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>

enum SearchScope {SONG, ALBUM};

@interface Search : NSObject

@property (strong, nonatomic) NSString *query;
@property (strong, nonatomic) NSArray *results;
@property (nonatomic) enum SearchScope searchFor;
@property (nonatomic) BOOL didUserCancel;
@property (nonatomic) BOOL isFinalSearch;

- (id)initWithQuery:(NSString *) query SearchFor:(enum SearchScope)searchFor IsFinal: (BOOL) isFinal;
- (void)searchWithBlock: (void (^)(NSString *query, enum SearchScope searchFor, NSArray *results))block OnFailure: (void (^)(void))failureBlock;
- (void)cancel;

@end
