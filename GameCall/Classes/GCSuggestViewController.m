//
//  GCSuggestViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-18.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCSuggestViewController.h"
#import "GCTwitterAPIClient.h"
#import "ABPerson.h"
#import "NSArray+Flatten.h"
#import "GCAddFriendTableViewCell.h"
#import "GCPermissionTableViewCell.h"
#import "UIColor+GCColors.h"
#import "PSAlertView.h"
#import "Constants.h"
#import "PFUser+GCAdditions.h"
#import "AppDelegate.h"
#import "GCPlainTableViewSectionHeaderView.h"

@interface GCSuggestViewController ()

@property (strong, nonatomic) NSArray *myFriends;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *facebooks;
@property (strong, nonatomic) NSMutableArray *twitters;
@property (strong, nonatomic) NSMutableArray *contacts;

- (IBAction)didTapCancelButton:(UIBarButtonItem *)button;
- (IBAction)didTapAccessoryButton:(UIButton *)button withEvent:(UIEvent *)event;

- (void)linkCurrentUserWithFacebook;
- (void)linkCurrentUserWithTwitter;
- (void)linkCurrentUserWithContacts;

- (void)intersectionOfMyFacebookFriendsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block;
- (void)intersectionOfMyTwitterFriendsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block;
- (void)intersectionOfMyContactsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block;

- (void)loadIntersectionOfMyFacebookFriendsAndGameCallUsers;
- (void)loadIntersectionOfMyTwitterFriendsAndGameCallUsers;
- (void)loadIntersectionOfMyContactsAndGameCallUsers;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeTableView;

@end

@implementation GCSuggestViewController

#pragma mark - GCFindFriendsViewController

- (NSMutableArray *)sections {
    if (!_sections) {
        _sections = [NSMutableArray arrayWithObjects:self.facebooks, self.twitters, self.contacts, nil];
    }
    
    return _sections;
}

- (NSMutableArray *)facebooks {
    if (!_facebooks) {
        _facebooks = [NSMutableArray new];
    }
    
    return _facebooks;
}

- (NSMutableArray *)twitters {
    if (!_twitters) {
        _twitters = [NSMutableArray new];
    }
    
    return _twitters;
}

- (NSMutableArray *)contacts {
    if (!_contacts) {
        _contacts = [NSMutableArray new];
    }
    
    return _contacts;
}

- (IBAction)didTapCancelButton:(UIBarButtonItem *)button {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)didTapAccessoryButton:(UIButton *)button withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    NSMutableArray *section = [self.sections objectAtIndex:indexPath.section];
    PFUser *friend = [section objectAtIndex:indexPath.row];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Adding friend", nil)];
    
    [[PFUser currentUser] addFriend:friend block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add friend", nil)];
            return;
        }
        
        [section removeObject:friend];
        
        if (section.count < 1) {
            [self.sections removeObjectAtIndex:indexPath.section];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
            
            return;
        }
        
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Added friend", nil)];
    }];
}

- (void)linkCurrentUserWithFacebook {
    NSArray *permissions = @[ @"email", @"publish_actions" ];
    
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
        
        [self loadIntersectionOfMyFacebookFriendsAndGameCallUsers];
    }];
}

- (void)linkCurrentUserWithTwitter {
    [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to connect with Twitter", nil)];
            return;
        }
                
        ACAccountStore *store = [[ACAccountStore alloc] init];
        ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        ACAccount *account = [[ACAccount alloc] initWithAccountType:type];
        ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:[PFTwitterUtils twitter].authToken tokenSecret:[PFTwitterUtils twitter].authTokenSecret];
        
        account.credential = credential;
        
        [store saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            if (!success && error.code != ACErrorAccountAlreadyExists) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to save account", nil)];
                return;
            }
            
            NSDictionary *parameters = @{ @"skip_status" : @(YES) };
            
            [[GCTwitterAPIClient sharedClient] getPath:@"account/verify_credentials" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *credentials) {
                [[PFUser currentUser] setObject:[credentials valueForKeyPath:@"id_str"] forKey:@"twId"];
                [[PFUser currentUser] saveEventually];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                TFLog(@"%@", error);
            }];
            
            [self loadIntersectionOfMyTwitterFriendsAndGameCallUsers];
        }];
    }];
}

- (void)linkCurrentUserWithContacts {
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
        
        [self loadIntersectionOfMyContactsAndGameCallUsers];
    }];
    
    [alertView show];
}

- (void)intersectionOfMyFacebookFriendsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block {
    TFLog(@"%@", @"Got this far!");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!self.myFriends) {
            PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
            PFQuery *myFriendsQuery = myFriendsRelation.query;
            NSError *errorFindingMyFriends;
            
            myFriendsQuery.className = @"_User";
            
            if (myFriendsQuery.hasCachedResult) {
                myFriendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
            }
            
            self.myFriends = [myFriendsQuery findObjects:&errorFindingMyFriends];
            
            if (errorFindingMyFriends) {
                if (block) {
                    block(nil, errorFindingMyFriends);
                }
                
                return;
            }
        }
    });
}

- (void)intersectionOfMyTwitterFriendsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block {    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!self.myFriends) {
            PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
            PFQuery *myFriendsQuery = myFriendsRelation.query;
            NSError *errorFindingMyFriends;
            
            myFriendsQuery.className = @"_User";
            
            if (myFriendsQuery.hasCachedResult) {
                myFriendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
            }
            
            self.myFriends = [myFriendsQuery findObjects:&errorFindingMyFriends];
            
            if (errorFindingMyFriends) {
                if (block) {
                    block(nil, errorFindingMyFriends);
                }
                
                return;
            }
        }
        
        [[GCTwitterAPIClient sharedClient] getPath:@"friends/ids?stringify_ids=true" parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *JSON) {
            NSArray *twIds = [JSON valueForKeyPath:@"ids"];
            PFQuery *usersQuery = [PFUser query];
            
            [usersQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
            [usersQuery whereKey:@"objectId" notContainedIn:[self.myFriends valueForKeyPath:@"objectId"]];
            [usersQuery whereKey:@"twId" containedIn:twIds];
            [usersQuery orderByAscending:@"lastName"];
            
            [usersQuery findObjectsInBackgroundWithBlock:block];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (block) {
                block(nil, error);
            }
        }];
    });
}

- (void)intersectionOfMyContactsAndGameCallUsersWithBlock:(void (^)(NSArray *users, NSError *error))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!self.myFriends) {
            PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
            PFQuery *myFriendsQuery = myFriendsRelation.query;
            NSError *errorFindingMyFriends;
            
            myFriendsQuery.className = @"_User";
            
            if (myFriendsQuery.hasCachedResult) {
                myFriendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
            }
            
            self.myFriends = [myFriendsQuery findObjects:&errorFindingMyFriends];
            
            if (errorFindingMyFriends) {
                if (block) {
                    block(nil, errorFindingMyFriends);
                }
                
                return;
            }
        }
        
        [ABPerson reachablePeopleWithBlock:^(NSArray *people) {
            NSArray *emails = (NSArray *)[[people valueForKeyPath:@"emails"] flatten];
            PFQuery *usersQuery = [PFUser query];
            
            [usersQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
            [usersQuery whereKey:@"objectId" notContainedIn:[self.myFriends valueForKeyPath:@"objectId"]];
            [usersQuery whereKey:@"email" containedIn:emails];
            [usersQuery orderByAscending:@"lastName"];
            
            [usersQuery findObjectsInBackgroundWithBlock:block];
        }];
    });
}

- (void)loadIntersectionOfMyFacebookFriendsAndGameCallUsers {
    [self intersectionOfMyFacebookFriendsAndGameCallUsersWithBlock:^(NSArray *users, NSError *error) {
        if (!users) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve users", nil)];
            return;
        }
        
        NSMutableArray *section = [self.sections objectAtIndex:GCSuggestTableViewSectionFacebook];

        if (users.count < 1) {
            [self.sections removeObject:section];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:GCSuggestTableViewSectionFacebook] withRowAnimation:UITableViewRowAnimationAutomatic];
            return;
        }
        
        [section removeAllObjects];
        [section addObjectsFromArray:users];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GCSuggestTableViewSectionFacebook] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)loadIntersectionOfMyTwitterFriendsAndGameCallUsers {    
    [self intersectionOfMyTwitterFriendsAndGameCallUsersWithBlock:^(NSArray *users, NSError *error) {
        if (!users) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve users", nil)];
            return;
        }
        
        NSMutableArray *section = [self.sections objectAtIndex:GCSuggestTableViewSectionTwitter];
        
        if (users.count < 1) {
            [self.sections removeObject:section];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:GCSuggestTableViewSectionTwitter] withRowAnimation:UITableViewRowAnimationAutomatic];
            return;
        }

        [section removeAllObjects];
        [section addObjectsFromArray:users];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GCSuggestTableViewSectionTwitter] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)loadIntersectionOfMyContactsAndGameCallUsers {        
    [self intersectionOfMyContactsAndGameCallUsersWithBlock:^(NSArray *users, NSError *error) {
        if (!users) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve users", nil)];
            return;
        }
        
        NSMutableArray *section = [self.sections objectAtIndex:GCSuggestTableViewSectionContacts];
        
        if (users.count < 1) {
            [self.sections removeObject:section];
            return;
        }
        
        [section removeAllObjects];
        [section addObjectsFromArray:users];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:GCSuggestTableViewSectionContacts] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {    
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.navigationItem.rightBarButtonItem.enabled = isReachable;
    self.view.userInteractionEnabled = isReachable;
    self.view.alpha = isReachable ? 1.f : 0.75f;
    
    if (isReachable) {
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self loadIntersectionOfMyFacebookFriendsAndGameCallUsers];
        }
        
        if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self loadIntersectionOfMyTwitterFriendsAndGameCallUsers];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"]) {
            [self loadIntersectionOfMyContactsAndGameCallUsers];
        }
    }
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case GCSuggestTableViewSectionFacebook:
            return NSLocalizedString(@"Facebook", nil);
            
        case GCSuggestTableViewSectionTwitter:
            return NSLocalizedString(@"Twitter", nil);
            
        case GCSuggestTableViewSectionContacts:
            return NSLocalizedString(@"Contacts", nil);
            
        default:
            return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRowsInSection = 0;
    NSMutableArray *rows = [self.sections objectAtIndex:section];
    
    switch (section) {
        case GCSuggestTableViewSectionFacebook:
            numberOfRowsInSection = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] ? rows.count : 1;
            break;
            
        case GCSuggestTableViewSectionTwitter:
            numberOfRowsInSection = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]] ? rows.count : 1;
            break;
            
        case GCSuggestTableViewSectionContacts:
            numberOfRowsInSection = [[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"] ? rows.count : 1;
            break;
    }
    
    return numberOfRowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier;
    NSMutableArray *section = [self.sections objectAtIndex:indexPath.section];
        
    switch (indexPath.section) {
        case GCSuggestTableViewSectionFacebook: {
            if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                CellIdentifier = @"PermissionCell";
                GCPermissionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.providerLogoImageView.image = [UIImage imageNamed:@"provider-logo-facebook"];
                cell.providerLabel.text = [self tableView:tableView titleForHeaderInSection:GCSuggestTableViewSectionFacebook];
                cell.purposeLabel.text = NSLocalizedString(@"Find friends from Facebook", nil);
                cell.accessoryView = [self detailDisclosureButton];
                
                return cell;
            }
            
            CellIdentifier = @"Cell";
            GCAddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            PFUser *user = [section objectAtIndex:indexPath.row];
            
            cell.user = user;
            
            return cell;
        };
            
        case GCSuggestTableViewSectionTwitter: {
            if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {                
                CellIdentifier = @"PermissionCell";
                GCPermissionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.providerLogoImageView.image = [UIImage imageNamed:@"provider-logo-twitter"];
                cell.providerLabel.text = [self tableView:tableView titleForHeaderInSection:GCSuggestTableViewSectionTwitter];
                cell.purposeLabel.text = NSLocalizedString(@"Find friends from Twitter", nil);
                cell.accessoryView = [self detailDisclosureButton];
                
                return cell;
            }
            
            CellIdentifier = @"Cell";
            GCAddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            PFUser *user = [section objectAtIndex:indexPath.row];
            
            cell.user = user;
            
            return cell;
        };
            
        case GCSuggestTableViewSectionContacts: {
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"]) {
                CellIdentifier = @"PermissionCell";
                GCPermissionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.providerLogoImageView.image = [UIImage imageNamed:@"provider-logo-contacts"];
                cell.providerLabel.text = [self tableView:tableView titleForHeaderInSection:GCSuggestTableViewSectionContacts];
                cell.purposeLabel.text = NSLocalizedString(@"Find friends from Contacts", nil);
                cell.accessoryView = [self detailDisclosureButton];
                
                return cell;
            }
            
            CellIdentifier = @"Cell";
            GCAddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            PFUser *user = [section objectAtIndex:indexPath.row];
            
            cell.user = user;
            
            return cell;
        };
        
        default:
            return nil;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {    
    GCPlainTableViewSectionHeaderView *view = [[GCPlainTableViewSectionHeaderView alloc] init];
    NSMutableArray *rows = [self.sections objectAtIndex:section];
    
    view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    BOOL hasSuggestedFriends = rows.count > 0;
    BOOL isLinkedWithUser = NO;
    
    switch (section) {
        case GCSuggestTableViewSectionFacebook:
            isLinkedWithUser = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
            break;
            
        case GCSuggestTableViewSectionTwitter:
            isLinkedWithUser = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
            break;
            
        case GCSuggestTableViewSectionContacts:
            isLinkedWithUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"];
            break;
    }
    
    if (hasSuggestedFriends || !isLinkedWithUser) {
        [view.activityIndicatorView stopAnimating];
    }
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.frame.size.width, cell.frame.size.height)];
    
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (![cell.reuseIdentifier isEqualToString:@"PermissionCell"]) {
        return;
    }
            
    if (indexPath.section == GCSuggestTableViewSectionFacebook) {
        [self linkCurrentUserWithFacebook];
    }
    
    if (indexPath.section == GCSuggestTableViewSectionTwitter) {
        [self linkCurrentUserWithTwitter];
    }
    
    if (indexPath.section == GCSuggestTableViewSectionContacts) {
        [self linkCurrentUserWithContacts];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (![cell.reuseIdentifier isEqualToString:@"PermissionCell"]) {
        return;
    }
    
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
}

- (void)viewDidUnload {
    [self setMyFriends:nil];
    [self setSections:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
