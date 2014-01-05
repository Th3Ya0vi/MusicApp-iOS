//
//  Album.h
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"

@interface Album : NSObject <NSCoding, NSCopying>

@property (strong, nonatomic) NSString *albumid;
@property (strong, nonatomic) NSString *albumArtBigURL;
@property (strong, nonatomic) NSString *albumArtSmallURL;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *cast;
@property (strong, nonatomic) NSArray *musicDirector;
@property (nonatomic) NSInteger year;
@property (strong, nonatomic) NSString *provider;
@property (strong, nonatomic) NSArray *songs;

- (id) initWithJSON:(NSDictionary *)json;


@end
