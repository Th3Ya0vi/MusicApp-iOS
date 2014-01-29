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

@interface EmptyPlaylistViewController ()

@end

@implementation EmptyPlaylistViewController

- (id)initWithNib
{
    self = [super initWithNibName:@"EmptyPlaylistView" bundle:nil];
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
        PlayerViewController *player = [[PlayerViewController alloc] initWithNib];
        
        NSMutableArray *viewControllers = [[[self tabBarController] viewControllers] mutableCopy];
        [viewControllers replaceObjectAtIndex:0 withObject:player];
        [[self tabBarController] setViewControllers:viewControllers];
    }
}

@end
