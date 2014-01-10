//
//  BollywoodAPIClient.m
//  Music
//
//  Created by Tushar Soni on 1/10/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "BollywoodAPIClient.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@interface BollywoodAPIClient ()

- (NSString *)urlForEndpoint: (enum BOLLYWOODAPI_ENDPOINT) endpoint Parameter: (NSString *)parameter;

@property (strong, nonatomic) NSString *developerID;
@property (strong, nonatomic) NSString *privateKey;
@property (strong, nonatomic) AFHTTPRequestOperation *currentSearch;
@property (strong, nonatomic) AFHTTPRequestOperationManager *requestOperationManager;

@end

@implementation BollywoodAPIClient

- (instancetype)initWithDeveloperID: (NSString *)developerID
                         PrivateKey: (NSString *)privateKey
{
    self = [super init];
    
    if (self)
    {
        [self setDeveloperID:developerID];
        [self setPrivateKey:privateKey];
        [self setRequestOperationManager:[[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.bollywoodapi.com/v1/"]]];
    }
    
    return self;
}

+ (instancetype) shared
{
    static BollywoodAPIClient *client;
    
    if (client == nil)
        client = [[BollywoodAPIClient alloc]
                  initWithDeveloperID:[NSString stringWithUTF8String:BOLLYWOODAPI_DEV_ID]
                  PrivateKey:[NSString stringWithUTF8String:BOLLYWOODAPI_PRIVATE_KEY]];
    
    return client;
}

- (void)fetchExploreAlbumsWithBlock: (void (^)(NSArray *titles, NSArray *albums))block
{
    [[self requestOperationManager] GET:[self urlForEndpoint:EXPLORE Parameter:nil] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSDictionary *response = (NSDictionary *)responseObject;
        
        NSMutableArray *titles = [response objectForKey:@"Titles"];
        NSMutableArray *albums = [[NSMutableArray alloc] init];
        
        [titles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSString *title = (NSString *)obj;
            NSArray *tempAlbums = [[response objectForKey:@"Albums"] objectForKey:title];
            NSMutableArray *albumsToGo = [[NSMutableArray alloc] init];
            
            [tempAlbums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [albumsToGo addObject:[[Album alloc] initWithJSON:obj]];
            }];
            
            [albums addObject:albumsToGo];
        }];
        
        block(titles, albums);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to fetch explore data");
    }];
    
}

- (void)searchFor: (enum SearchScope) scope
          IsFinal: (BOOL)isFinal
            Query: (NSString *)query
          Success:(void (^)(NSArray *objects))successBlock
          Failure:(void (^)(void))failureBlock
{
    [self cancelCurrentSearch];
    
    NSString *url;
    
    if (scope == ALBUM && isFinal)
        url = [self urlForEndpoint:SEARCH_ALBUM Parameter:query];
    else if (scope == ALBUM && isFinal == NO)
        url = [self urlForEndpoint:SEARCH_LIKE_ALBUM Parameter:query];
    else if (scope == SONG && isFinal)
        url = [self urlForEndpoint:SEARCH_SONG Parameter:query];
    else if (scope == SONG && isFinal == NO)
        url = [self urlForEndpoint:SEARCH_LIKE_SONG Parameter:query];

    AFHTTPRequestOperation *newSearch = [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (scope == ALBUM)
            successBlock([Album albumsWithJSONArray:responseObject]);
        else if(scope == SONG)
            successBlock([Song songsWithJSONArray:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] != NSURLErrorCancelled)
            failureBlock();
    }];
    [self setCurrentSearch:newSearch];
}

- (void)postUserActivity
{
    [[self requestOperationManager] setRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSArray *activityCopy = [[[User currentUser] activity] copy];
    [[[User currentUser] activity] removeAllObjects];
    
    NSMutableArray *activityToPost = [[NSMutableArray alloc] init];
    [activityCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [activityToPost addObject:[obj dictionary]];
    }];
    
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:activityToPost forKey:@"data"];
    
    [[self requestOperationManager] POST:[self urlForEndpoint:POST_USER_ACTIVITY Parameter:nil] parameters:json success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Posted activity: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to post activity: %@", error);
        [[[User currentUser] activity] addObjectsFromArray:activityCopy];
    }];
}

- (void)createNewUserWithSuccess:(void (^)(User *))successBlock
                         Failure:(void (^)(void))failureBlock
{
#if DEBUG
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef setObject:[NSNumber numberWithInt:2] forKey:@"userid"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"playlist"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"activity"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"downloads"];
    [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
    [userDef synchronize];
    successBlock([User currentUser]);
#else
    [[self requestOperationManager] GET:[self urlForEndpoint:CREATE_NEW_USER Parameter:nil] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *) responseObject;
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        [userDef setObject:[response objectForKey:@"UserID"] forKey:@"userid"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"playlist"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"activity"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"downloads"];
        [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
        [userDef synchronize];
        
        successBlock([User currentUser]);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error creating user: %@", error);
        failureBlock();
    }];
#endif
    
}

- (NSString *)urlForEndpoint: (enum BOLLYWOODAPI_ENDPOINT) endpoint Parameter: (NSString *)parameter;
{
    if (parameter)
        parameter = [parameter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *queryStrings = [self urlQueryStrings];
    
    switch (endpoint)
    {
        case SEARCH_ALBUM:
            return [NSString stringWithFormat:@"search/albums/%@%@", parameter, queryStrings];
            break;
        case SEARCH_LIKE_ALBUM:
            return [NSString stringWithFormat:@"search/like/albums/%@%@", parameter, queryStrings];
            break;
        case SEARCH_SONG:
            return [NSString stringWithFormat:@"search/songs/%@%@", parameter, queryStrings];
            break;
        case SEARCH_LIKE_SONG:
            return [NSString stringWithFormat:@"search/like/songs/%@%@", parameter, queryStrings];
            break;
        case CREATE_NEW_USER:
            return [NSString stringWithFormat:@"user/create%@", queryStrings];
            break;
        case POST_USER_ACTIVITY:
            return [NSString stringWithFormat:@"user/%d/activity%@", [[User currentUser] userid], queryStrings];
            break;
        case EXPLORE:
            return [NSString stringWithFormat:@"explore%@", queryStrings];
            break;
    }
}

- (void)cancelCurrentSearch
{
    [[self currentSearch] cancel];
}

- (NSString *)urlQueryStrings
{
    NSTimeInterval timestampDBL = [[[NSDate alloc] init] timeIntervalSince1970];
    NSString *timestamp = [NSString stringWithFormat:@"%d", (int)timestampDBL];
    
    /**http://stackoverflow.com/questions/14533621/objective-c-hmac-sha-256-gives-wrong-nsdata-output**/
    const char *cKey  = [[self privateKey] cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [timestamp cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < sizeof(cHMAC); i++)
    {
        [result appendFormat:@"%02hhx", cHMAC[i]];
    }
    /**--------**/
    
    NSString *url = [NSString stringWithFormat:@"?Timestamp=%@&DeveloperID=%@&hmac=%@", timestamp, [self developerID], result];
    
    return url;
}

@end
