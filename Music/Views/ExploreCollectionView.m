//
//  ExploreCollectionView.m
//  Music
//
//  Created by Tushar Soni on 1/22/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "ExploreCollectionView.h"

@implementation ExploreCollectionView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setShowsHorizontalScrollIndicator:NO];
        [self setContentInset:UIEdgeInsetsMake(0, 20, 0, 20)];
        
        [self registerNib:[UINib nibWithNibName:@"ExploreCollectionCellView" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"ExploreCollectionCell"];
    }
    return self;
}

@end
