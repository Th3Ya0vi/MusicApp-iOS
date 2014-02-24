//
//  Analytics.m
//  Music
//
//  Created by Tushar Soni on 2/23/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "Analytics.h"
#import "User.h"
#import "AFHTTPRequestOperationManager.h"

@interface Analytics ()
@property (strong, nonatomic) NSString *localFileURL;
@property (strong, nonatomic) NSMutableArray *events;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskForPosting;
@property (strong, nonatomic) AFHTTPRequestOperationManager *requestManager;
@end

@implementation Analytics

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        [self setLocalFileURL:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"analytics.data"]];
        
        if (![self loadData])
            [self setEvents:[[NSMutableArray alloc] init]];
        
        [self setBackgroundTaskForPosting:UIBackgroundTaskInvalid];
        
        [self setRequestManager:[[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://54.201.193.207/Analytics/src/index.php/"]]];
        [[self requestManager] setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [[self requestManager] setResponseSerializer:[AFJSONResponseSerializer serializer]];
    }
    
    return self;
}

+ (instancetype) shared
{
    static Analytics *analytics;
    if (analytics == nil)
        analytics = [[Analytics alloc] init];
    
    return analytics;
}

- (void)saveData
{
    [NSKeyedArchiver archiveRootObject:[self events] toFile:[self localFileURL]];
    NSLog(@"Analytics: Saved data to file.");
}

- (BOOL)loadData
{
    return NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self localFileURL] isDirectory:NO])
    {
        [self setEvents:[NSKeyedUnarchiver unarchiveObjectWithFile:[self localFileURL]]];
        NSLog(@"Analytics: Loaded events from file");
        return YES;
    }
    NSLog(@"Analytics: Data file does not exist");
    return NO;
}

- (void)logEventWithName: (NSString *)name
{
    [self logEventWithName:name Attributes:[NSDictionary dictionary]];
}

- (void)logEventWithName: (NSString *)name Attributes: (NSDictionary *)attributes
{
    NSLog(@"Analytics: Adding event (%@ => %@)", name, attributes);
    
    NSNumber *timestamp = [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]];
    NSNumber *userid = [NSNumber numberWithInteger:[[User currentUser] userid]];
    
    NSMutableArray *attributesArray = [[NSMutableArray alloc] init];
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [attributesArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:key, obj, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"Name", @"Value", nil]]];
    }];
    
    NSDictionary *event = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:name, attributesArray, timestamp, userid, nil]
                                                      forKeys:[NSArray arrayWithObjects:@"Name", @"Attributes", @"Timestamp", @"UserID", nil]];
    [[self events] addObject:event];
}

- (void)tagScreen: (NSString *)screenName
{
    [self logEventWithName:@"Page View" Attributes:[NSDictionary dictionaryWithObject:screenName forKey:@"Screen"]];
}

- (void)post
{
    if ([self backgroundTaskForPosting] != UIBackgroundTaskInvalid)
    {
        NSLog(@"Analytics: Already posting. Skipping now.");
        return;
    }
    if ([[self events] count] == 0)
    {
        NSLog(@"Analytics: No events to post. Skipping now.");
        return;
    }
    
    [self setBackgroundTaskForPosting:[[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Post Analytics" expirationHandler:^{
        NSLog(@"Analytics: Failed to post events (Background task expired)");
        [self setBackgroundTaskForPosting:UIBackgroundTaskInvalid];
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTaskForPosting]];
    }]];
    NSLog(@"Analytics: Attempting to post events");
    
    NSDictionary *toPost = [NSDictionary dictionaryWithObject:[self events] forKey:@"Events"];
    
    [[self requestManager] POST:@"activity" parameters:toPost success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        if ([[responseObject objectForKey:@"Message"] isEqualToString:@"Success"])
        {
            [[self events] removeObjectsInArray:[toPost objectForKey:@"Events"]];
            NSLog(@"Analytics: Posted events");
        }
        else
            NSLog(@"Analytics: Failed to post events (%@)", responseObject);

        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTaskForPosting]];
        [self setBackgroundTaskForPosting:UIBackgroundTaskInvalid];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Analytics: Failed to post events (%@)", [operation responseString]);
        
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTaskForPosting]];
        [self setBackgroundTaskForPosting:UIBackgroundTaskInvalid];
    }];
}

@end
