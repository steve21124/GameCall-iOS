//
//  GCInviteViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-21.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCInviteViewController.h"
#import "Constants.h"

@interface GCInviteViewController ()

@property (strong, nonatomic) UITableViewController *facebookFriendViewController;
@property (strong, nonatomic) UITableViewController *twitterFriendViewController;
@property (strong, nonatomic) UITableViewController *contactsViewController;

- (IBAction)segmentDidChange:(UISegmentedControl *)control;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeBackgroundImage;

@end

@implementation GCInviteViewController

#pragma mark - GCInviteViewController

- (UITableViewController *)facebookFriendViewController {
    if (!_facebookFriendViewController) {
        _facebookFriendViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCFacebookFriendViewControllerIdentifier];
    }
    
    return _facebookFriendViewController;
}

- (UITableViewController *)twitterFriendViewController {
    if (!_twitterFriendViewController) {
        _twitterFriendViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCTwitterFriendViewControllerIdentifier];
    }
    
    return _twitterFriendViewController;
}

- (UITableViewController *)contactsViewController {
    if (!_contactsViewController) {
        _contactsViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCContactsViewControllerIdentifier];
    }
    
    return _contactsViewController;
}

- (IBAction)segmentDidChange:(UISegmentedControl *)control {
    UITableViewController *fromViewController = [self.childViewControllers objectAtIndex:0];
    UITableViewController *toViewController;
    
    switch (control.selectedSegmentIndex) {
        case GCInviteViewControllerSegmentIndexFacebook:
            toViewController = self.facebookFriendViewController;
            break;

        case GCInviteViewControllerSegmentIndexTwitter:
            toViewController = self.twitterFriendViewController;
            break;

        case GCInviteViewControllerSegmentIndexContacts:
            toViewController = self.contactsViewController;
            break;
    }
    
    [self addChildViewController:toViewController];
    
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.0 options:UIViewAnimationOptionTransitionNone animations:^{
        [fromViewController.view removeFromSuperview];

    } completion:^(BOOL finished) {
        [fromViewController willMoveToParentViewController:nil];
        [fromViewController removeFromParentViewController];
        
        [self.view addSubview:toViewController.view];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    UISegmentedControl *segmentedControl = (UISegmentedControl *)self.navigationItem.titleView;
    
    segmentedControl.enabled = segmentedControl.userInteractionEnabled = isReachable;
    
    for (UIViewController *childViewController in self.childViewControllers) {
        childViewController.view.userInteractionEnabled = isReachable;
        childViewController.view.alpha = isReachable ? 1.f : 0.75f;
    }
}

- (void)customizeBackgroundImage {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addChildViewController:self.facebookFriendViewController];
    [self.view addSubview:self.facebookFriendViewController.view];
    
    [self customizeBackgroundImage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setFacebookFriendViewController:nil];
    [self setTwitterFriendViewController:nil];
    [self setContactsViewController:nil];

    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    UITableViewController *childViewController = [self.childViewControllers objectAtIndex:0];
    
    childViewController.view.frame = self.view.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
