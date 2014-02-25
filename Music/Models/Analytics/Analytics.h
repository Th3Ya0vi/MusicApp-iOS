//
//  Analytics.h
//  Music
//
//  Created by Tushar Soni on 2/23/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EVENT_DEVICE_TOKEN          @"Device Token"
#define EVENT_SONG_CHANGE           @"Song Change"
#define EVENT_SEARCH                @"Search"
#define EVENT_NEW_USER              @"New User"
#define EVENT_CRASH_RESOLVER        @"Crash Resolver"
#define EVENT_SONG_DOWNLOAD         @"Song Download"
#define EVENT_RATE                  @"Rate"
#define EVENT_SONG_LISTEN           @"Song Listen"
#define EVENT_SONG_ADD              @"Song Add Playlist"
#define EVENT_SHUFFLE               @"Shuffle"
#define EVENT_DOWNLOAD_ALL          @"Download All Songs"
#define EVENT_SONG_ADD_ALL          @"Add All Songs Playlist"

@interface Analytics : NSObject

@property (nonatomic, getter = isLoggingEnabled) BOOL loggingEnabled;

- (instancetype) init;
+ (instancetype) shared;

- (void)tagScreen: (NSString *)screenName;

- (void)logEventWithName: (NSString *)name;
- (void)logEventWithName: (NSString *)name Attributes: (NSDictionary *)attributes;

- (void)post;
- (void)saveData;

@end
