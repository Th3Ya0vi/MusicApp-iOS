//
//  SongOptionsViewController.h
//  Music
//
//  Created by Tushar Soni on 1/25/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>

@interface SongOptionsViewController : UIViewController

@property (strong, nonatomic) Song *song;
@property (strong, nonatomic) NSString *origin;

- (id)initWithSong: (Song *)song Origin: (NSString *)origin;

@end
