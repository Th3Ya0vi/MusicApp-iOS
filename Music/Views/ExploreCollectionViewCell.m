//
//  ExploreCollectionViewCell.m
//  Music
//
//  Created by Tushar Soni on 1/22/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "ExploreCollectionViewCell.h"

@interface ExploreCollectionViewCell ()

@property (weak, nonatomic) UILabel *labelTitle;
@property (weak, nonatomic) UIImageView *albumArt;

@end

@implementation ExploreCollectionViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self setAlbumArt:(UIImageView *)[self viewWithTag:800]];
        [self setLabelTitle:(UILabel *)[self viewWithTag:801]];
        
        [[[self albumArt] layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
        [[[self albumArt] layer] setBorderWidth:0.5];
        [[self albumArt] setImage:[UIImage imageNamed:@"DefaultAlbumArtDark"]];
    }
    
    return self;
}

- (void)setTitleText: (NSString *)text
{
    [[self labelTitle] setFrame:CGRectMake(0, 95, 90, 20)];
    [[self labelTitle] setText:text];
    [[self labelTitle] sizeToFit];
}

- (void)setImageFromAlbum: (Album *)album
{
    [[AlbumArtManager shared] fetchAlbumArtForAlbum:album Size:SMALL From:@"ExploreView" CompletionBlock:^(UIImage *image, BOOL didSucceed) {
        if (didSucceed)
            [[self albumArt] setImage:image];
    }];
}

@end
