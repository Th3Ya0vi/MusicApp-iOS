//
//  Playlist.m
//  Music
//
//  Created by Tushar Soni on 1/26/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "Playlist.h"
#import "Player.h"
#import "Analytics.h"

@interface Playlist ()

@property (strong, nonatomic) NSMutableArray *playlist;

@end

@implementation Playlist

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        [self setPlaylist:[[User currentUser] playlist]];
        [self setCurrentIndex:[[User currentUser] currentPlaylistIndex]];
    }
    
    return self;
}

+ (instancetype)shared
{
    static Playlist *playlist;
    if (playlist == nil)
        playlist = [[Playlist alloc] init];
    
    return playlist;
}

- (NSUInteger)count
{
    return [[self playlist] count];
}

- (NSUInteger)currentIndex
{
    return [[self playlist] indexOfObjectIdenticalTo:[self currentSong]];
}

- (void) setCurrentIndex:(NSUInteger)currentIndex
{
    if (currentIndex < [self count])
        [self setCurrentSong:[[self playlist] objectAtIndex:currentIndex]];
}

- (void)removeSong:(Song *)song
{
    if ([self currentSong] == song)
        [self setCurrentSong:nil];
    [[self playlist] removeObjectIdenticalTo:song];
}

- (Song *)currentSong
{
    if (_currentSong == nil && [self count] > 0)
        _currentSong = [[self playlist] objectAtIndex:0];
    return _currentSong;
}

- (void)addSongInEnd:(Song *)song Origin: (NSString *)origin
{
    if (song == nil)
        return;
    
    [[self playlist] addObject:[song copy]];
    //[Activity addWithSong:song action:ADDEDTOPLAYLIST extra:origin];
    [[Analytics shared] logEventWithName:@"Song Add Playlist" Attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[song songid], origin, nil]
                                                                                     forKeys:[NSArray arrayWithObjects:@"SongID", @"Origin", nil]]];
}

- (void)addSong:(Song *)song After:(Song *)after Origin: (NSString *)origin
{
    if (song == nil)
        return;
    if (after == nil)
        return [self addSongInEnd:song Origin:origin];
    
    [[self playlist] insertObject:[song copy] atIndex:[[self playlist] indexOfObjectIdenticalTo:after] + 1];
    //[Activity addWithSong:song action:ADDEDTOPLAYLIST extra:origin];
    [[Analytics shared] logEventWithName:@"Song Add Playlist" Attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[song songid], origin, nil]
                                                                                     forKeys:[NSArray arrayWithObjects:@"SongID", @"Origin", nil]]];
}

- (void)addSong:(Song *)song Before:(Song *)before Origin: (NSString *)origin
{
    if (song == nil)
        return;
    if (before == nil)
        return [self addSongInEnd:song Origin:origin];
    
    [[self playlist] insertObject:[song copy] atIndex:[[self playlist] indexOfObjectIdenticalTo:before] - 1];
    //[Activity addWithSong:song action:ADDEDTOPLAYLIST extra:origin];
    [[Analytics shared] logEventWithName:@"Song Add Playlist" Attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[song songid], origin, nil]
                                                                                     forKeys:[NSArray arrayWithObjects:@"SongID", @"Origin", nil]]];
}

- (Song *)songBefore: (Song *)song
{
    if ([[self playlist] indexOfObjectIdenticalTo:song] == 0)
        return nil;
    return [[self playlist] objectAtIndex:[[self playlist] indexOfObjectIdenticalTo:song] - 1];
}

- (Song *)songAfter:(Song *)song
{
    if ([[self playlist] indexOfObjectIdenticalTo:song] == [self count] - 1)
        return nil;
    return [[self playlist] objectAtIndex:[[self playlist] indexOfObjectIdenticalTo:song] + 1];
}

- (Song *)songAtIndex:(NSUInteger)index
{
    if (index >= [self count])
        return nil;
    return [[self playlist] objectAtIndex:index];
}

- (Song *) songInPlaylistWithSong: (Song *)song
{
    if ([self indexOfSong:song] == NSNotFound)
        return nil;
    return [self songAtIndex:[self indexOfSong:song]];
}

- (void) removeSongAtIndex: (NSUInteger) index
{
    [self removeSong:[[self playlist] objectAtIndex:index]];
}

- (void) swapSong: (Song *)songA With: (Song *)songB
{
    [[self playlist] exchangeObjectAtIndex:[self indexOfSong:songA] withObjectAtIndex:[self indexOfSong:songB]];
}

- (BOOL) isCurrentSongFirst
{
    return [self songBefore:[self currentSong]] == nil;
}

- (BOOL) isCurrentSongLast
{
    return [self songAfter:[self currentSong]] == nil;
}

- (NSUInteger) indexOfSong: (Song *)song
{
    __block NSInteger index = NSNotFound;
    [[self playlist] enumerateObjectsUsingBlock:^(Song* obj, NSUInteger idx, BOOL *stop)
     {
         if ([song isEqual:obj])
         {
             index = idx;
             *stop = YES;
         }
     }];
    return index;
}

- (void) shuffle
{
    [[self playlist] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return rand()%100 < 50;
    }];
}

- (void) clear
{
    [[self playlist] removeAllObjects];
    [self setCurrentSong:nil];
}

- (void)moveSong:(Song *)songA After:(Song *)songB
{
    [[self playlist] removeObjectAtIndex:[[self playlist] indexOfObjectIdenticalTo:songA]];
    [[self playlist] insertObject:[songA copy] atIndex:[self indexOfSong:songB] + 1];
}

@end
