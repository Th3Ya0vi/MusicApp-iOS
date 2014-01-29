//
//  NowPlayingViewController.h
//  Music
//
//  Created by Tushar Soni on 1/23/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"

@interface NowPlayingViewController : UIViewController

@property (strong, nonatomic) Song *song;

- (id)initWithSong: (Song *)song;

@end
