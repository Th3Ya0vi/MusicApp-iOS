//
//  Defines.h
//  Music
//
//  Created by Tushar Soni on 2/26/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#ifndef Music_Defines_h
#define Music_Defines_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

/**ANALYTICS**/
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
/**----------**/

#define currentRowAvailability [[[self searchResults] objectAtIndex:indexPath.row] availability]
#define didCurrentRowFail    currentRowAvailability != LOCAL && currentRowAvailability != DOWNLOADING

#define isPlayerPlaying [[Player shared] currentStatus] == PLAYING

#define nextSongInPlaylist  [[Playlist shared] songAfter:[[Playlist shared] currentSong]]
#define nextLocalSongInPlaylist  [[Playlist shared] localSongAfter:[[Playlist shared] currentSong]]
#define previousLocalSongInPlaylist  [[Playlist shared] localSongBefore:[[Playlist shared] currentSong]]
#define previousSongInPlaylist [[Playlist shared] songBefore:[[Playlist shared] currentSong]]
#define previousSongAuto    ([[Player shared] isOfflineModeOn]) ? previousLocalSongInPlaylist : previousSongInPlaylist
#define nextSongAuto    ([[Player shared] isOfflineModeOn]) ? nextLocalSongInPlaylist : nextSongInPlaylist

#define MIN_SEARCH_LENGTH   3

#endif
