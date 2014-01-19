//
//  PlayerManager.m
//  Music
//
//  Created by Tushar Soni on 12/10/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "AFNetworkReachabilityManager.h"
#import "Player.h"
#import "Activity.h"
#import "AlbumArtManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface Player ()

@property (nonatomic) UIBackgroundTaskIdentifier bgTask;

@end

@implementation Player

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        self.currentStatus = STOPPED;
        self.isRepeatOn = NO;
        self.isShuffleOn = NO;
        self.timesFailed = 0;
        self.bgTask = UIBackgroundTaskInvalid;
        
        __block Player *weakSelf = self;

        [self addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
            if (!time.value)
                return;
            
            if ([weakSelf currentStatus] == LOADING)
            {
                [weakSelf setCurrentStatus: PLAYING];
                [weakSelf setMediaInfo];
                [weakSelf setTimesFailed:0];
                [[UIApplication sharedApplication] endBackgroundTask:[weakSelf bgTask]];
                [weakSelf setBgTask:UIBackgroundTaskInvalid];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerUpdated" object:weakSelf];
        }];
        
        [self addObserver:self forKeyPath:@"currentItem" options:0 context:nil];
    }
    
    return self;
}

+ (instancetype)shared
{
    static Player *player;
    if (player == nil)
    {
        player = [[Player alloc] init];
    }
    return player;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentItem"])
    {
        [[self currentItem] addObserver:self forKeyPath:@"status" options:0 context:nil];
        [[self currentItem] addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
    }
    else if([keyPath isEqualToString:@"status"]
            && [[self currentItem] status] == AVPlayerItemStatusFailed)
    {
        [self setTimesFailed:[self timesFailed]+1];
        if ([self timesFailed] == 3)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SongFailed" object:nil];
            [self setCurrentStatus:STOPPED];
            [self setTimesFailed:0];
        }
        else if ([self timesFailed] < 3)
        {
            NSLog(@"Failed to play song. trying again!");
            [self loadCurrentSong];
        }
    }
    else if([keyPath isEqualToString:@"playbackBufferEmpty"]
            && [[self currentItem] isPlaybackBufferEmpty])
    {
        [self togglePlayPause];
    }
    else if([keyPath isEqualToString:@"playbackBufferEmpty"]
            && ![[self currentItem] isPlaybackBufferEmpty]
            && [[self currentItem] isPlaybackLikelyToKeepUp])
    {
            [self togglePlayPause];
    }
}

- (float)getPercentCompleted
{
    return CMTimeGetSeconds([self currentTime])/CMTimeGetSeconds([[self currentItem] duration]);
}

- (void)togglePlayPause
{
    switch ([self currentStatus])
    {
        case PLAYING:
            [self pause];
            [self setCurrentStatus: PAUSED];
            break;
        case PAUSED:
            [self play];
            [self setCurrentStatus: PLAYING];
            break;
        case STOPPED:
            [self loadCurrentSong];
            [self play];
            break;
        default:
            return;
            break;
    }
    
    [self setMediaInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerUpdated" object:self];
}

- (void)play
{
    if ([self currentStatus] == STOPPED)
    {
        if ([self bgTask] != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:[self bgTask]];
        
        self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"PlayNewSong" expirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:[self bgTask]];
        }];
        
        [self setCurrentStatus:LOADING];
        
        Song *song = [Song currentSongInPlaylist];
        
        [self replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:[song mp3]]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadNextSongDependingOnRepeat) name:AVPlayerItemDidPlayToEndTimeNotification object:[self currentItem]];
    }
    
    [super play];
}

- (BOOL) loadCurrentSong
{
    if ([[[User currentUser] playlist] count] == 0) return NO;
    
    [self replaceCurrentItemWithPlayerItem:nil];
    enum Status oldStatus = [self currentStatus];
    [self setCurrentStatus:STOPPED];
    
    if (oldStatus == PLAYING || oldStatus == FINISHED || oldStatus == LOADING)
        [self play];
    
    [self setMediaInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerUpdated" object:self];
    
    return YES;
}

- (void)loadNextSongDependingOnRepeat
{
    [self setCurrentStatus:FINISHED];
    [Activity addWithSong:[Song currentSongInPlaylist] action:FINISHEDLISTENING extra:[NSString stringWithFormat:@"%f", [self getPercentCompleted]]];
    ([self isRepeatOn]) ? [self loadCurrentSong] : [self loadNextSong];
}

- (BOOL) loadNextSong
{
    if ([self isCurrentIndexLast])
    {
        [self setCurrentStatus:STOPPED];
        return [self loadCurrentSong];
    }
    if ([self currentStatus] != STOPPED && [self currentStatus] != FINISHED)
        [Activity addWithSong:[Song currentSongInPlaylist] action:FINISHEDLISTENING extra:[NSString stringWithFormat:@"%f", [self getPercentCompleted]]];
    [[User currentUser] setCurrentPlaylistIndex:[[User currentUser] currentPlaylistIndex] + 1];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongChanged" object:self];
    return [self loadCurrentSong];
}

- (BOOL) loadPreviousSong
{
    if ([self isCurrentIndexFirst]) return NO;
    if ([self currentStatus] != STOPPED)
        [Activity addWithSong:[Song currentSongInPlaylist] action:FINISHEDLISTENING extra:[NSString stringWithFormat:@"%f", [self getPercentCompleted]]];
    [[User currentUser] setCurrentPlaylistIndex:[[User currentUser] currentPlaylistIndex] - 1];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SongChanged" object:self];
    return [self loadCurrentSong];

}

- (BOOL) isCurrentIndexLast
{
    if ([[[User currentUser] playlist] count] == 0) return YES;
    return ([[User currentUser] currentPlaylistIndex] == [[[User currentUser] playlist] count] - 1) ? YES : NO;
}

- (BOOL) isCurrentIndexFirst
{
    return ([[User currentUser] currentPlaylistIndex] == 0) ? YES : NO;
}

- (void)seekToPercent: (float)percent
{
    float duration = CMTimeGetSeconds([[self currentItem] duration]) * percent;
    [self seekToTime:CMTimeMake(duration, 1)];
    [self setMediaInfo];
    [self togglePlayPause];
}

- (void)setMediaInfo
{
    Song *song = [Song currentSongInPlaylist];
    UIImage *albumArt = [[AlbumArtManager shared] existingImageForAlbum:[song album] Size:BIG];
    
    NSArray *keys = [NSArray arrayWithObjects:
                     MPMediaItemPropertyTitle,
                     MPMediaItemPropertyAlbumTitle,
                     MPNowPlayingInfoPropertyElapsedPlaybackTime,
                     MPMediaItemPropertyPlaybackDuration,
                     MPNowPlayingInfoPropertyPlaybackRate,
                     MPMediaItemPropertyArtwork,
                     nil];
    
    NSArray *values = [NSArray arrayWithObjects:
                       [song name],
                       [[song album] name],
                       [NSNumber numberWithInteger:CMTimeGetSeconds([self currentTime])],
                       [NSNumber numberWithInteger:CMTimeGetSeconds([[self currentItem] duration])],
                       [NSNumber numberWithInt:1],
                       (albumArt) ? [[MPMediaItemArtwork alloc] initWithImage:albumArt] : [[MPMediaItemArtwork alloc] init],
                       nil];
    
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

- (NSString *)timeLeftAsString
{
    float duration = CMTimeGetSeconds([[self currentItem] duration]) - CMTimeGetSeconds([self currentTime]);
    if (duration >= 0 == NO)
        return @"0:00";
    float mins = duration / 60.00;
    NSInteger secs = (mins - floor(mins)) * 60.00;
    NSInteger intMins = mins;
    
    NSString *strVal = [NSString stringWithFormat:@"%d:%02d", intMins, secs];
    return strVal;
}

@end
