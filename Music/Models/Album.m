//
//  Album.m
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "Album.h"
#import "Song.h"

@implementation Album

- (id) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    
    if (self)
    {
        self.albumid = [json objectForKey:@"AlbumID"];
        self.name = [json objectForKey:@"Name"];
        self.albumArtBigURL = [json objectForKey:@"AlbumArtBig"];
        self.albumArtSmallURL = [json objectForKey:@"AlbumArtSmall"];
        self.cast = [json objectForKey:@"Cast"];
        self.musicDirector = [json objectForKey:@"MusicDirector"];
        self.year = [[json objectForKey:@"Year"] integerValue];
        self.provider = [json objectForKey:@"Provider"];
        
        if ([self.cast isKindOfClass:[NSArray class]] == NO)
            self.cast = [[NSArray alloc] init];
        if ([self.musicDirector isKindOfClass:[NSArray class]] == NO)
            self.musicDirector = [[NSArray alloc] init];
        
        
        if ([json objectForKey:@"Songs"] != nil)
        {
            NSArray *songsFromJson = [json objectForKey:@"Songs"];
            NSMutableArray *songs = [[NSMutableArray alloc] initWithCapacity:[songsFromJson count]];
            for (int i=0;i<[songsFromJson count];i++)
                [songs addObject:[[Song alloc] initWithJSON:[songsFromJson objectAtIndex:i]]];
            self.songs = [songs copy];
        }
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.albumid = [aDecoder decodeObjectForKey:@"albumid"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.albumArtBigURL = [aDecoder decodeObjectForKey:@"albumArtBigURL"];
        self.albumArtSmallURL = [aDecoder decodeObjectForKey:@"albumArtSmallURL"];
        self.cast = [aDecoder decodeObjectForKey:@"cast"];
        self.musicDirector = [aDecoder decodeObjectForKey:@"musicDirector"];
        self.year = [aDecoder decodeIntegerForKey:@"year"];
        self.provider = [aDecoder decodeObjectForKey:@"provider"];
        
        if ([aDecoder containsValueForKey:@"songs"])
            self.songs = [aDecoder decodeObjectForKey:@"songs"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.albumid forKey:@"albumid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.albumArtBigURL forKey:@"albumArtBigURL"];
    [aCoder encodeObject:self.albumArtSmallURL forKey:@"albumArtSmallURL"];
    [aCoder encodeObject:self.cast forKey:@"cast"];
    [aCoder encodeObject:self.musicDirector forKey:@"musicDirector"];
    [aCoder encodeInteger:self.year forKey:@"year"];
    [aCoder encodeObject:self.provider forKey:@"provider"];
    
    if ([self songs])
        [aCoder encodeObject:self.songs forKey:@"songs"];
}

- (id) copyWithZone:(NSZone *)zone
{
    Album *copy = [[Album alloc] init];
    
    if (copy)
    {
        [copy setAlbumid:[self albumid]];
        [copy setName:[[self name] copyWithZone:zone]];
        [copy setAlbumArtBigURL:[[self albumArtBigURL] copyWithZone:zone]];
        [copy setAlbumArtSmallURL:[[self albumArtSmallURL] copyWithZone:zone]];
        [copy setCast:[[self cast] copyWithZone:zone]];
        [copy setMusicDirector:[[self musicDirector] copyWithZone:zone]];
        [copy setYear:[self year]];
        [copy setProvider:[[self provider] copyWithZone:zone]];
        
        if ([self songs])
        {
            NSMutableArray *copySongs = [[NSMutableArray alloc] initWithCapacity:[[self songs] count]];
            [[self songs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [copySongs addObject:[obj copyWithZone:zone]];
            }];
            [copy setSongs:copySongs];
        }
    }
    
    return copy;
}
@end
