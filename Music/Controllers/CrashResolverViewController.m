//
//  CrashResolverViewController.m
//  Music
//
//  Created by Tushar Soni on 2/19/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "CrashResolverViewController.h"
#import "AppDelegate.h"

@interface CrashResolverViewController ()

@property (nonatomic) BOOL didFix;

@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UIButton *buttonFix;
@property (weak, nonatomic) IBOutlet UIButton *buttonContinue;

@end

@implementation CrashResolverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:@"Crash Resolver"];
        [self setDidFix:NO];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self lblStatus] setText:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetAllSetings
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    [userDef setInteger:0 forKey:@"currentPlaylistIndex"];
    
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"activity"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"playlist"];
    [userDef setObject:[NSKeyedArchiver archivedDataWithRootObject:[[NSMutableArray alloc] init]]
                forKey:@"downloads"];
    
    [userDef synchronize];
}

- (void)resumeNormalLoading
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)fixIt:(UIButton *)sender
{
    [self resetAllSetings];
    [self setDidFix:YES];
    [[self lblStatus] setText:@"Filmi should be fixed now. Tap 'Continue'"];
    [[self buttonFix] setEnabled:NO];
    [[self buttonContinue] setBackgroundImage:[UIImage imageNamed:@"continue"] forState:UIControlStateNormal];
}

- (IBAction)workingFine:(UIButton *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didCrash"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self resumeNormalLoading];
}

@end
