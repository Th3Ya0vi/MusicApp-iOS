//
//  Explore.h
//  Music
//
//  Created by Tushar Soni on 12/8/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Explore : NSObject

@property (strong, nonatomic) NSArray *titles;
@property (strong, nonatomic) NSMutableArray *albums;

- (void)fetchWithBlock:(void (^)(void))block;
- (void)cancel;

@end
