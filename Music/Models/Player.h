//
//  PlayerManager.h
//  Music
//
//  Created by Tushar Soni on 12/10/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "User.h"

enum Status {LOADING, PLAYING, PAUSED, NOT_STARTED, FINISHED};

/*
Loading: A song has been requested to be played and is currently being downloaded from the network.
PLAYING: A song has been (partially) downloaded from the network and is being played.
PAUSED: A song has been (partially) downloaded from the network and is not being played.
NOT_STARTED: A song has not been downloaded from the network but it is the current song.
FINISHED: A song has been completely downloaded from the network and has been played till the end.
*/

@interface Player : AVPlayer

@property (nonatomic) enum Status currentStatus;
@property (nonatomic, getter = getPercentCompleted) float percentCompleted;
@property (nonatomic) BOOL isRepeatOn;
@property (nonatomic) NSInteger timesFailed;
@property (nonatomic) BOOL isOfflineModeOn;

+ (instancetype)shared;
- (void)togglePlayPause;
- (void)stop;
- (void)loadSong: (Song *)song ShouldPlay: (BOOL) play;
- (void)seekToPercent: (float)percent;
- (void)setMediaInfo;
- (NSString *)timeLeftAsString;

@end
