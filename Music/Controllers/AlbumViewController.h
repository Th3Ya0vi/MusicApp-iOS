//
//  AlbumViewController.h
//  Music
//
//  Created by Tushar Soni on 11/27/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"


@interface AlbumViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) Album* album;
@property (strong, nonatomic) NSString *origin;
@property (nonatomic) BOOL downloadsOnly;

- (id)initWithAlbum: (Album *) album Origin: (NSString *)origin;

@end
