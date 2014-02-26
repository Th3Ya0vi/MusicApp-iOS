//
//  Playlist.h
//  Music
//
//  Created by Tushar Soni on 1/26/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Song.h"
#import "Album.h"

@interface Playlist : NSObject

@property (strong, nonatomic) Song *currentSong;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic) NSUInteger count;

+ (instancetype) shared;

- (void) addSongInEnd: (Song *)song Origin: (NSString *)origin;
- (void) addSong: (Song *)song After: (Song *)after Origin: (NSString *)origin;
- (void) addSong: (Song *)song Before: (Song *)before Origin: (NSString *)origin;

- (Song *) localSongAfter: (Song *)song;
- (Song *) localSongBefore: (Song *)song;
- (Song *) songAtIndex: (NSUInteger) index;
- (Song *) songAfter: (Song *)song;
- (Song *) songBefore: (Song *)song;
- (Song *) songInPlaylistWithSong: (Song *)song;

- (BOOL) isCurrentSongLast;
- (BOOL) isCurrentSongFirst;
- (NSUInteger) indexOfSong: (Song *)song;

- (void) removeSong: (Song *)song;
- (void) removeSongAtIndex: (NSUInteger) index;

- (void) swapSong: (Song *)songA With: (Song *)songB;
- (void) moveSong: (Song *)songA After: (Song *)songB;
- (void) shuffle;
- (void) clear;

/**FIX**/
- (Song *)currentSong;
/******/

@end
