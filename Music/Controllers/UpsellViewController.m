//
//  UpsellViewController.m
//  Music
//
//  Created by Tushar Soni on 4/7/14.
//  Copyright (c) 2014 Tushar Soni. All rights reserved.
//

#import "UpsellViewController.h"
#import "Analytics.h"
#import "iRate.h"
#import <Social/Social.h>

@interface UpsellViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelUpsell;

@property (strong, nonatomic) NSArray *texts;
@property (strong, nonatomic) NSString *origin;
@property (nonatomic) NSUInteger chosenIndex;
@property (nonatomic) NSUInteger chosenService;
/*
Chosen Service
 0: Rate on iTunes
 1: Facebook
 2: Twitter
*/

@end

@implementation UpsellViewController

- (id)initWithOrigin: (NSString *)origin
{
    int random = arc4random() % 2;
    if (random == 0)
        self = [super initWithNibName:@"RateView" bundle:nil];
    else if (random == 1)
        self = [super initWithNibName:@"ShareView" bundle:nil];
    
    if (self)
    {
        [self setOrigin:origin];
        [self setChosenService:random];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addBorders];
}
- (void)addBorders
{
    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
    [topBorder setBackgroundColor:[UIColor lightGrayColor]];
    
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, [[self view] frame].size.height - 1, 320, 1)];
    [bottomBorder setBackgroundColor:[UIColor lightGrayColor]];
    
    [[self view] addSubview:topBorder];
    [[self view] addSubview:bottomBorder];
}

- (void)action
{
    if ([self chosenService] > 0)
    {
        SLComposeViewController *compose = [SLComposeViewController composeViewControllerForServiceType:[self chosenService] == 1 ? SLServiceTypeFacebook : SLServiceTypeTwitter];
        
        [compose setInitialText:@"Listen & Download Bollywood Songs on your iPhone for Free #filmi #bollywood"];
        [compose addURL:[NSURL URLWithString:@"http://www.filmiapp.com"]];
        [compose addImage:[UIImage imageNamed:@"logo"]];
        
        SLComposeViewController *weakCompose = compose;
        [compose setCompletionHandler:^(SLComposeViewControllerResult result) {
            [[Analytics shared] logEventWithName:EVENT_SHARE Attributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:([weakCompose serviceType] == SLServiceTypeFacebook) ? @"Facebook" : @"Twitter", (result == SLComposeViewControllerResultDone) ? @"Yes" : @"No", nil] forKeys:[NSArray arrayWithObjects:@"On", @"Success", nil]]];
            [weakCompose dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [self presentViewController:compose animated:YES completion:nil];
    }
    else
    {
        [[Analytics shared] logEventWithName:EVENT_RATE Attributes:[NSDictionary dictionaryWithObject:@"Attempt" forKey:@"Type"]];
        [[iRate sharedInstance] openRatingsPageInAppStore];
    }
}

#pragma mark - IBActions

- (IBAction)upsellButton:(UIButton *)sender
{
    [self action];
}

- (IBAction)facebookButton:(id)sender
{
    [self setChosenService:1];
    [self action];
}

- (IBAction)twitterButton:(id)sender
{
    [self setChosenService:2];
    [self action];
}

@end
