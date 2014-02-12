//
//  DownloadsManager.h
//  Music
//
//  Created by Tushar Soni on 2/10/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Song.h"

@interface DownloadsManager : NSObject

+ (instancetype) shared;

- (void) downloadSong: (Song *)song Origin: (NSString *)origin;
- (void) deleteSongFromDownloads: (Song *)song;

@end
