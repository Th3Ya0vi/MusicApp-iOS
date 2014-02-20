//
//  BollywoodAPIClient.m
//  Music
//
//  Created by Tushar Soni on 1/10/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "LocalyticsSession.h"
#import "BollywoodAPIClient.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@interface BollywoodAPIClient ()

- (NSString *)urlForEndpoint: (enum BOLLYWOODAPI_ENDPOINT) endpoint Parameter: (NSString *)parameter;

@property (strong, nonatomic) NSString *developerID;
@property (strong, nonatomic) NSString *privateKey;
@property (strong, nonatomic) AFHTTPRequestOperation *currentSearch;
@property (strong, nonatomic) AFHTTPRequestOperationManager *requestOperationManager;
@property (nonatomic) UIBackgroundTaskIdentifier activityTask;

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
        [self setActivityTask:UIBackgroundTaskInvalid];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useTestURL"] == YES)
        {
            NSLog(@"Using Test URL");
            [self setRequestOperationManager:[[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://54.201.193.207/Bollywood-API-Dev/v1/"]]];
        }
        else
        {
            NSLog(@"Using Production URL");
            [self setRequestOperationManager:[[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.bollywoodapi.com/v1/"]]];
        }
    
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
    [[self requestOperationManager] setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSString *url = [self urlForEndpoint:EXPLORE Parameter:nil];
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
    [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

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
    [[self requestOperationManager] setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
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
    
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
    __block NSMutableDictionary *flurrySearchParams = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:(scope == ALBUM) ? @"Albums" : @"Songs", query, (isFinal) ? @"Yes" : @"No", nil]
                                                                   forKeys:[NSArray arrayWithObjects:@"For", @"Query", @"Is Final", nil]] mutableCopy];
    
    AFHTTPRequestOperation *newSearch = [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (scope == ALBUM)
            successBlock([Album albumsWithJSONArray:responseObject]);
        else if(scope == SONG)
            successBlock([Song songsWithJSONArray:responseObject]);
        
        [flurrySearchParams setObject:@"Yes" forKey:@"Success"];
        [flurrySearchParams setObject:[NSNumber numberWithInteger:[responseObject count]] forKey:@"Result Count"];
        [[LocalyticsSession shared] tagEvent:@"Search" attributes:flurrySearchParams];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([error code] != NSURLErrorCancelled)
            failureBlock();
        
        [flurrySearchParams setObject:@"No" forKey:@"Success"];
        [flurrySearchParams setObject:[error localizedDescription] forKey:@"Error"];
        [[LocalyticsSession shared] tagEvent:@"Search" attributes:flurrySearchParams];
    }];
    
    [self setCurrentSearch:newSearch];
}

- (void)postUserActivity
{
    if ([self activityTask] != UIBackgroundTaskInvalid)
    {
        NSLog(@"Already posting activity. Skipping.. %d", [self activityTask]);
        return;
    }
    if ([[[User currentUser] activity] count] == 0)
    {
        NSLog(@"No activity to post. Skipping..");
        return;
    }
    
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [[self requestOperationManager] setRequestSerializer:[AFJSONRequestSerializer serializer]];
    
    NSString *url = [self urlForEndpoint:POST_USER_ACTIVITY Parameter:nil];
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
    
    NSArray *activityCopy = [[[User currentUser] activity] copy];
    [[[User currentUser] activity] removeAllObjects];
    
    NSMutableArray *activityToPost = [[NSMutableArray alloc] init];
    [activityCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [activityToPost addObject:[obj dictionary]];
    }];
    
    [self setActivityTask:[[UIApplication sharedApplication] beginBackgroundTaskWithName:@"PostActivity" expirationHandler:^{
        NSLog(@"Failed to post activity: background time exceeded");
        [[[User currentUser] activity] addObjectsFromArray:activityCopy];
        [[UIApplication sharedApplication] endBackgroundTask:[self activityTask]];
        [self setActivityTask:UIBackgroundTaskInvalid];
    }]];
    
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:activityToPost forKey:@"data"];
    
    [[self requestOperationManager] POST:url parameters:json success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([[responseObject objectForKey:@"message"] isEqualToString:@"success"])
            NSLog(@"Posted activity");
        else
        {
            NSLog(@"Failed to post activity (invalid response): %@", responseObject);
            [[[User currentUser] activity] addObjectsFromArray:activityCopy];
        }
        
        [[UIApplication sharedApplication] endBackgroundTask:[self activityTask]];
        [self setActivityTask:UIBackgroundTaskInvalid];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to post activity: %@", [operation responseString]);
        [[[User currentUser] activity] addObjectsFromArray:activityCopy];
        
        [[UIApplication sharedApplication] endBackgroundTask:[self activityTask]];
        [self setActivityTask:UIBackgroundTaskInvalid];
    }];
}

- (void)createNewUserWithSuccess:(void (^)(User *))successBlock
                         Failure:(void (^)(void))failureBlock
{
    [[self requestOperationManager] setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSString *url = [self urlForEndpoint:CREATE_NEW_USER Parameter:nil];
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
#if DEBUG

        NSLog(@"Using default user");
        NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
        [userDef setObject:[NSNumber numberWithInt:155] forKey:@"userid"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"playlist"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"activity"];
        [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"downloads"];
        [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
        [userDef synchronize];
        successBlock([User currentUser]);
#else
        NSLog(@"Creating new user");
        [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *response = (NSDictionary *) responseObject;
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            [userDef setObject:[response objectForKey:@"UserID"] forKey:@"userid"];
            [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"playlist"];
            [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"activity"];
            [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSArray alloc] init]] forKey:@"downloads"];
            [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
            [userDef synchronize];
            
            [Flurry logEvent:@"User_Create" withParameters:[NSDictionary dictionaryWithObject:[response objectForKey:@"UserID"] forKey:@"UserID"]];
            
            successBlock([User currentUser]);

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error creating user: %@", error);
            failureBlock();
        }];
#endif
}

- (void)fetchSongWithSongID: (NSString *)songid CompletionBlock: (void(^)(Song *song))block
{
    [[self requestOperationManager] setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSString *url = [self urlForEndpoint:FETCH_SONG Parameter:songid];
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
    
    [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        Song *song = [[Song alloc] initWithJSON:responseObject];
        block(song);
        NSLog(@"Fetched data for %@", [song name]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching song: %@", error);
    }];
}

- (void)fetchAlbumWithAlbumID: (NSString *)albumid CompletionBlock: (void(^)(Album *album))block
{
    [[self requestOperationManager] setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [[self requestOperationManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    
    NSString *url = [self urlForEndpoint:FETCH_ALBUM Parameter:albumid];
    [[[self requestOperationManager] requestSerializer] setValue:[self hmacForRequest:url] forHTTPHeaderField:@"hmac"];
    
    
    [[self requestOperationManager] GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        Album *album = [[Album alloc] initWithJSON:responseObject];
        block(album);
        NSLog(@"Fetched data for %@", [album name]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error fetching album: %@", error);
    }];
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
        case FETCH_SONG:
            return [NSString stringWithFormat:@"song/%@%@/album", parameter, queryStrings];
            break;
        case FETCH_ALBUM:
            return [NSString stringWithFormat:@"album/%@%@/songs", parameter, queryStrings];
            break;
    }
}

- (void)cancelCurrentSearch
{
    [[self currentSearch] cancel];
}

- (NSString *)hmacForRequest: (NSString *) request
{
    request = [NSString stringWithFormat:@"/%@", request];
    /**http://stackoverflow.com/questions/14533621/objective-c-hmac-sha-256-gives-wrong-nsdata-output**/
     const char *cKey  = [[self privateKey] cStringUsingEncoding:NSASCIIStringEncoding];
     const char *cData = [request cStringUsingEncoding:NSASCIIStringEncoding];
     unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
     CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
     
     NSMutableString *result = [NSMutableString string];
     for (int i = 0; i < sizeof(cHMAC); i++)
     {
     [result appendFormat:@"%02hhx", cHMAC[i]];
     }
    /**--------**/

    return result;
}

- (NSString *)urlQueryStrings
{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *url = [NSString stringWithFormat:@"?DeveloperID=%@&Version=%@", [self developerID], appVersion];

    return url;
}

@end
