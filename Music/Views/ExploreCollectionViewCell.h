//
//  ExploreCollectionViewCell.h
//  Music
//
//  Created by Tushar Soni on 1/22/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"
#import "AlbumArtManager.h"

@interface ExploreCollectionViewCell : UICollectionViewCell

- (void)setTitleText: (NSString *)text;
- (void)setImageFromAlbum: (Album *)album;

@end
