//
//  GCConnectionsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-13.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCConnectionsViewController.h"
#import "Constants.h"
#import "GCTwitterAPIClient.h"
#import "PSAlertView.h"

enum {
    GCConnectionsViewControllerSegmentIndexFacebook = 0,
    GCConnectionsViewControllerSegmentIndexTwitter,
    GCConnectionsViewControllerSegmentIndexContacts
};

typedef NSInteger GCConnectionsViewControllerSegmentIndex;

@interface GCConnectionsViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) UITableViewController *facebookFriendViewController;
@property (strong, nonatomic) UIViewController *twitterFriendViewController;
@property (strong, nonatomic) UIViewController *contactsViewController;

- (IBAction)segmentDidChange:(UISegmentedControl *)control;

- (void)linkUserWithFacebook;
- (void)linkUserWithTwitter;
- (void)linkUserWithContacts;

- (void)customizeBackgroundImage;
- (void)customizeLeftBarButtonItem;

@end

@implementation GCConnectionsViewController

#pragma mark - GCConnectionsViewController
@synthesize segmentedControl = _segmentedControl;

- (UITableViewController *)facebookFriendViewController {
    if (!_facebookFriendViewController) {
        _facebookFriendViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCFacebookFriendViewControllerIdentifier];
    }
    
    return _facebookFriendViewController;
}

- (UIViewController *)twitterFriendViewController {
    if (!_twitterFriendViewController) {
        _twitterFriendViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCTwitterFriendViewControllerIdentifier];
    }
    
    return _twitterFriendViewController;
}

- (UIViewController *)contactsViewController {
    if (!_contactsViewController) {
        _contactsViewController = [self.storyboard instantiateViewControllerWithIdentifier:GCContactsViewControllerIdentifier];
    }
    
    return _contactsViewController;
}

- (IBAction)segmentDidChange:(UISegmentedControl *)control {    
    UIViewController *from = [self.childViewControllers objectAtIndex:0], *to;
    
    switch (control.selectedSegmentIndex) {
        case GCConnectionsViewControllerSegmentIndexFacebook:
            to = self.facebookFriendViewController;
            break;
            
        case GCConnectionsViewControllerSegmentIndexTwitter:
            to = self.twitterFriendViewController;
            break;
            
        case GCConnectionsViewControllerSegmentIndexContacts:
            to = self.contactsViewController;
            break;
    }
    
    [self addChildViewController:to];
    [to didMoveToParentViewController:self];
    
    [self transitionFromViewController:from toViewController:to duration:0.0 options:UIViewAnimationOptionTransitionNone animations:^{
        [from.view removeFromSuperview];
    
    } completion:^(BOOL finished) {
        [from willMoveToParentViewController:nil];
        [from removeFromParentViewController];
        
        [self.view addSubview:to.view];
        
        switch (control.selectedSegmentIndex) {
            case GCConnectionsViewControllerSegmentIndexFacebook: {
                if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                    return;
                }
                
                [self linkUserWithFacebook];
                
            } break;
                
            case GCConnectionsViewControllerSegmentIndexTwitter: {
                if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                    return;
                }
                
                [self linkUserWithTwitter];
                
            } break;
                
            case GCConnectionsViewControllerSegmentIndexContacts: {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"]) {
                    return;
                }
                
                [self linkUserWithContacts];
                
            } break;
        }
    }];
}

- (void)linkUserWithFacebook {
    NSString *title = NSLocalizedString(@"Facebook", nil);
    NSString *message = NSLocalizedString(@"Would you like sign in with Facebook to find your friends?", nil);
    PSAlertView *alertView = [[PSAlertView alloc] initWithTitle:title message:message];
    
    [alertView setCancelButtonWithTitle:NSLocalizedString(@"No thanks", nil) block:^{}];
    [alertView addButtonWithTitle:NSLocalizedString(@"Sign in", nil) block:^{
        NSArray *permissions = @[ @"email", @"publish_actions" ];
        
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *user, NSError *error) {
            if (!user) {
                TFLog(@"%@", error);
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to sign in with Facebook", nil)];
                return;
            }
            
            [PFFacebookUtils linkUser:[PFUser currentUser] permissions:permissions block:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to connect with Facebook", nil)];
                    return;
                }
                
                PF_FBRequest *request = [PF_FBRequest requestForMe];
                
                [request startWithCompletionHandler:^(PF_FBRequestConnection *connection, PF_FBGraphObject<PF_FBGraphUser> *me, NSError *error) {
                    if (!me) {
                        TFLog(@"%@", error);
                        return;
                    }
                    
                    [PFUser currentUser][@"fbId"] = me.id;
                    [[PFUser currentUser] saveEventually];
                }];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:GCFacebookLinkedWithUserNotification object:nil];
            }];
        }];
    }];
    
    [alertView show];
}

- (void)linkUserWithTwitter {
    NSString *title = NSLocalizedString(@"Twitter", nil);
    NSString *message = NSLocalizedString(@"Would you like sign in with Twitter to find your friends?", nil);
    PSAlertView *alertView = [[PSAlertView alloc] initWithTitle:title message:message];
    
    [alertView setCancelButtonWithTitle:NSLocalizedString(@"No thanks", nil) block:^{}];
    [alertView addButtonWithTitle:NSLocalizedString(@"Sign in", nil) block:^{
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *user, NSError *error) {
            if (!user) {
                TFLog(@"%@", error);
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to sign in with Twitter", nil)];
                return;
            }
            
            [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to connect with Twitter", nil)];
                    return;
                }
                
                [SVProgressHUD show];
                
                ACAccountStore *store = [[ACAccountStore alloc] init];
                ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
                ACAccount *account = [[ACAccount alloc] initWithAccountType:type];
                ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:[PFTwitterUtils twitter].authToken tokenSecret:[PFTwitterUtils twitter].authTokenSecret];
                
                account.credential = credential;
                
                [store saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                    if (!success && error.code != ACErrorAccountAlreadyExists) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to save Twitter account", nil)];
                        return;
                    }
                    
                    NSDictionary *parameters = @{ @"skip_status" : @(YES) };
                    
                    [[GCTwitterAPIClient sharedClient] getPath:@"account/verify_credentials" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *credentials) {
                        [[PFUser currentUser] setObject:[credentials valueForKeyPath:@"id_str"] forKey:@"twId"];
                        [[PFUser currentUser] saveEventually];
                        
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        TFLog(@"%@", error);
                    }];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GCTwitterLinkedWithUserNotification object:nil];
                }];
            }];
        }];
    }];
    
    [alertView show];
}

- (void)linkUserWithContacts {
    NSString *title = NSLocalizedString(@"Contacts", nil);
    NSString *message = NSLocalizedString(@"To find your friends, GameCall needs to send your contacts to our server.", nil);
    
    PSAlertView *alertView = [[PSAlertView alloc] initWithTitle:title message:message];
    
    [alertView setCancelButtonWithTitle:NSLocalizedString(@"Don't Allow", nil) block:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"contactsLinkedWithUser"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    
    [alertView addButtonWithTitle:NSLocalizedString(@"OK", nil) block:^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"contactsLinkedWithUser"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GCContactsLinkedWithUserNotification object:nil];
    }];
    
    [alertView show];
}

- (void)customizeBackgroundImage {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

- (void)customizeLeftBarButtonItem {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeBackgroundImage];
    [self customizeLeftBarButtonItem];
    
    [self addChildViewController:self.facebookFriendViewController];
    [self.view addSubview:self.facebookFriendViewController.view];
}

- (void)viewDidUnload {
    [self setSegmentedControl:nil];
    [self setFacebookFriendViewController:nil];
    [self setTwitterFriendViewController:nil];
    [self setContactsViewController:nil];
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }
    
    [self linkUserWithFacebook];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIViewController *childViewController = [self.childViewControllers objectAtIndex:0];
    
    childViewController.view.frame = self.view.frame;
}

@end
