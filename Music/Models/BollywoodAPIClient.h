//
//  BollywoodAPIClient.h
//  Music
//
//  Created by Tushar Soni on 1/10/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "secret.h"

enum BOLLYWOODAPI_ENDPOINT {    SEARCH_SONG,
                                SEARCH_LIKE_SONG,
                                SEARCH_ALBUM,
                                SEARCH_LIKE_ALBUM,
                                CREATE_NEW_USER,
                                POST_USER_ACTIVITY,
                                EXPLORE,
                                FETCH_SONG,
                                FETCH_ALBUM
                            };

enum SearchScope {SONG, ALBUM};

@interface BollywoodAPIClient : NSObject


- (instancetype)initWithDeveloperID: (NSString *)developerID
                         PrivateKey: (NSString *)privateKey;

+ (instancetype) shared;

- (void)fetchExploreAlbumsWithBlock: (void (^)(NSArray *titles, NSArray *albums))block;

- (void)searchFor: (enum SearchScope) scope
          IsFinal: (BOOL)isFinal
            Query: (NSString *)query
          Success:(void (^)(NSArray *objects))successBlock
          Failure:(void (^)(void))failureBlock;

- (void)createNewUserWithSuccess: (void (^)(User *user))successBlock
                         Failure: (void (^)(void))failureBlock;

- (void)fetchSongWithSongID: (NSString *)songid
            CompletionBlock: (void(^)(Song *song))block;

- (void)fetchAlbumWithAlbumID: (NSString *)albumid
              CompletionBlock: (void(^)(Album *album))block;

- (void)postUserActivity;

- (void)cancelCurrentSearch;

@end
