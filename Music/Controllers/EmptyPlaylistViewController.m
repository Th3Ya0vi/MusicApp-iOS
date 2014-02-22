//
//  EmptyPlaylistViewController.m
//  Music
//
//  Created by Tushar Soni on 12/15/13.
//  Copyright (c) 2013 Tushar Soni. All rights reserved.
//

#import "EmptyPlaylistViewController.h"
#import "PlayerViewController.h"
#import "User.h"
#import "Playlist.h"
#import "Flurry.h"

@interface EmptyPlaylistViewController ()

@end

@implementation EmptyPlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [[self navigationItem] setTitle:@"Empty Playlist"];
        [[self tabBarItem] setTitle:@"Player"];
        [[self tabBarItem] setImage:[UIImage imageNamed:@"music"]];
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ( [[Playlist shared] count] > 0)
    {
        PlayerViewController *player = [[PlayerViewController alloc] initWithNibName:nil bundle:nil];
        
        NSMutableArray *viewControllers = [[[self tabBarController] viewControllers] mutableCopy];
        [viewControllers replaceObjectAtIndex:0 withObject:player];
        [[self tabBarController] setViewControllers:viewControllers];
    }
    
    [Flurry logPageView];
}

@end
