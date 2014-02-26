//
//  Analytics.h
//  Music
//
//  Created by Tushar Soni on 2/23/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analytics : NSObject

@property (nonatomic, getter = isLoggingEnabled) BOOL loggingEnabled;

- (instancetype) init;
+ (instancetype) shared;

- (void)setPushToken: (NSData *)pushToken;

- (void)tagScreen: (NSString *)screenName;

- (void)logEventWithName: (NSString *)name;
- (void)logEventWithName: (NSString *)name Attributes: (NSDictionary *)attributes;

- (void)post;
- (void)saveData;

@end
