//
//  Song.h
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Album.h"

enum SongAvailability {CLOUD, LOCAL, DOWNLOADING, UNAVAILABLE};

@interface Song : NSObject <NSCoding, NSCopying>

@property (strong, nonatomic) NSString *songid;
@property (strong, nonatomic) NSString *albumid;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *singers;
@property (strong, nonatomic) NSURL *mp3;
@property (strong, nonatomic) Album *album;
@property (nonatomic) enum SongAvailability availability;
@property (nonatomic, strong) NSURL *localMp3Path;
@property (strong, nonatomic, getter = getPlayerItem) AVPlayerItem *playerItem;

- (instancetype) initWithJSON:(NSDictionary *)json;
+ (NSArray *) songsWithJSONArray: (NSArray *)jsonArray;
- (void)startDownloadWithOrigin: (NSString *)origin;
- (BOOL) deleteLocalFile;

@end
