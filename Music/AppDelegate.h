//
//  AppDelegate.h
//  Music
//
//  Created by Tushar Soni on 11/26/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iRate.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, iRateDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
