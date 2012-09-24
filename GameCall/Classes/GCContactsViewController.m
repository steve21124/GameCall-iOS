//
//  GCContactsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-22.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCContactsViewController.h"
#import "Constants.h"
#import "ABPerson.h"
#import "PFUser+GCAdditions.h"
#import "NSArray+Flatten.h"
#import "GCPlainTableViewSectionHeaderView.h"
#import "GCAddFriendTableViewCell.h"
#import "GCInviteTableViewCell.h"
#import "PSAlertView.h"
#import "PSActionSheet.h"
#import "GCTwilioAPIClient.h"
#import "GCMandrillAPIClient.h"
#import "PFUser+GCUser.h"

@interface GCContactsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *suggestions;
@property (strong, nonatomic) NSMutableArray *contacts;

- (IBAction)didTapAddButton:(UIButton *)button forEvent:(UIEvent *)event;
- (IBAction)didTapInviteButton:(UIButton *)button forEvent:(UIEvent *)event;

- (void)loadObjects;

@end

@implementation GCContactsViewController

#pragma mark - GCContactsViewController

- (NSMutableArray *)sections {
    if (!_sections) {
        _sections = [NSMutableArray new];
    }
    
    return _sections;
}

- (NSMutableArray *)suggestions {
    if (!_suggestions) {
        _suggestions = [NSMutableArray new];
    }
    
    return _suggestions;
}

- (NSMutableArray *)contacts {
    if (!_contacts) {
        _contacts = [NSMutableArray new];
    }
    
    return _contacts;
}

- (IBAction)didTapAddButton:(UIButton *)button forEvent:(UIEvent *)event {
    UITouch *touch = [event touchesForView:button].anyObject;
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    PFUser *friend = [self.suggestions objectAtIndex:indexPath.row];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Adding friend", nil)];
    
    [[PFUser currentUser] addFriend:friend block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add friend", nil)];
            return;
        }

        [self.suggestions removeObject:friend];

        if (self.suggestions.count < 1) {
            [self.sections removeObject:self.suggestions];

            [self.tableView beginUpdates];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        } else {
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Added friend", nil)];
    }];
}

- (IBAction)didTapInviteButton:(UIButton *)button forEvent:(UIEvent *)event {
    UITouch *touch = [event touchesForView:button].anyObject;
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    [self.searchDisplayController.searchBar resignFirstResponder];
    
    ABPerson *contact = [self.contacts objectAtIndex:indexPath.row];
    PSActionSheet *sheet = [PSActionSheet sheetWithTitle:[NSString stringWithFormat:NSLocalizedString(@"How would you like to invite %@ to GameCall?", nil), contact.firstName]];
    NSString *myFirstName = [[PFUser currentUser][@"firstName"] capitalizedString];
    NSString *myFullName = [NSString stringWithFormat:@"%@ %@", [[PFUser currentUser][@"firstName"] capitalizedString], [[PFUser currentUser][@"lastName"] capitalizedString]];
    NSString *myEmail = [PFUser currentUser][@"email"];
    NSString *hisOrHerFirstName = contact.firstName;
    NSString *hisOrHerFullName = contact.compositeName;
    
    for (NSString *phone in contact.phones) {
        [sheet addButtonWithTitle:phone block:^{
            NSDictionary *attributes = @{ @"myFirstName" : myFirstName, @"otherFirstName" : hisOrHerFirstName, @"to" : phone };
            
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending invitation", nil)];
            
            [[GCTwilioAPIClient sharedClient] sendSMSMessageWithAttributes:attributes block:^(NSDictionary *JSON, NSError *error) {
                if (!JSON) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to send invitation", nil)];
                    return;
                }
                
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Invitation sent", nil)];
            }];
        }];
    }
    
    for (NSString *email in contact.emails) {
        [sheet addButtonWithTitle:email block:^{
            NSDictionary *attributes = @{
            @"from" : myFirstName,
            @"from_name": myFullName,
            @"from_email" : myEmail,
            @"to" : hisOrHerFirstName,
            @"name" : hisOrHerFullName,
            @"email" : email
            };
            
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Sending invitation", nil)];
            
            [[GCMandrillAPIClient sharedClient] sendTemplateWithAttributes:attributes block:^(NSDictionary *response) {
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Invitation sent", nil)];
            }];
        }];
    }
    
    [sheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
    [sheet showInView:self.view];
}

- (void)loadObjects {
    [SVProgressHUD show];
    
    [ABPerson reachablePeopleWithBlock:^(NSArray *people) {        
        if (!people) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve contacts", nil)];
             return;
        }
        
        [self.contacts removeAllObjects];
        [self.contacts addObjectsFromArray:people];
        [self.sections removeAllObjects];
        [self.sections addObject:self.contacts];
        
        NSIndexSet *contactsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
            return section == self.contacts;
        }];
        
        [self.tableView beginUpdates];
        [self.tableView insertSections:contactsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        [SVProgressHUD dismiss];
        
        [[PFUser currentUser] findFriendsInBackgroundWithBlock:^(NSArray *friends, NSError *error) {
            if (!friends) {
                return;
            }
            
            NSArray *emails = [[people valueForKeyPath:@"emails"] flatten];
            PFQuery *query = [PFUser query];
            
            [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
            [query whereKey:@"objectId" notContainedIn:[friends valueForKeyPath:@"objectId"]];
            [query whereKey:@"email" containedIn:emails];
            [query orderByAscending:@"lastName"];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *suggestions, NSError *error) {
                if (!suggestions || suggestions.count < 1) {
                    return;
                }
                
                [self.suggestions removeAllObjects];
                [self.suggestions addObjectsFromArray:suggestions];
                [self.sections insertObject:self.suggestions atIndex:0];
                
                [self.tableView beginUpdates];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    NSIndexSet *contactsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
                        return section == self.contacts;
                    }];
                    NSMutableArray *duplicates = [NSMutableArray new];
                    NSMutableArray *indexPaths = [NSMutableArray new];
                    
                    for (PFUser *suggestion in self.suggestions) {
                        for (ABPerson *contact in self.contacts) {
                            for (NSString *email in contact.emails) {
                                if ([suggestion[@"email"] isEqualToString:email]) {
                                    NSUInteger section = contactsIndexSet.firstIndex;
                                    NSUInteger row = [self.contacts indexOfObject:contact];
                                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                                    
                                    [duplicates addObject:contact];
                                    [indexPaths addObject:indexPath];
                                }
                            }
                        }
                    }
                    
                    [self.contacts removeObjectsInArray:duplicates];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        NSIndexSet *contactsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
                            return section == self.contacts;
                        }];
                        
                        if (self.contacts.count < 1) {
                            [self.sections removeObject:self.contacts];
                            
                            [self.tableView beginUpdates];
                            [self.tableView deleteSections:contactsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                            [self.tableView endUpdates];
                            
                            return;
                        }
                        
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.tableView endUpdates];
                    });
                });
            }];
        }];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *rows = [self.sections objectAtIndex:section];
    
    return rows.count;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier;
    NSMutableArray *section = [self.sections objectAtIndex:indexPath.section];
    
    if (section == self.suggestions) {
        CellIdentifier = @"SuggestionCell";
        GCAddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        PFUser *user = [self.suggestions objectAtIndex:indexPath.row];
        
        cell.user = user;
        
        return cell;
    }
    
    CellIdentifier = @"ContactCell";
    GCInviteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    ABPerson *contact = [self.contacts objectAtIndex:indexPath.row];
    UIImage *photo = contact.image ? contact.image : [UIImage imageNamed:@"photo-placeholder"];
    NSString *name = contact.compositeName;
    
    cell.photoImageView.image = photo;
    cell.nameLabel.text = name;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSMutableArray *rows = [self.sections objectAtIndex:section];
    
    return (rows == self.suggestions) ? NSLocalizedString(@"Suggestions", nil) : NSLocalizedString(@"Invite", nil);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GCPlainTableViewSectionHeaderView *view = [[GCPlainTableViewSectionHeaderView alloc] init];
    NSMutableArray *rows = [self.sections objectAtIndex:section];
    
    view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    if (rows.count > 0) {
        [view.activityIndicatorView stopAnimating];
    } else {
        [view.activityIndicatorView startAnimating];
    }
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.f;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:GCContactsLinkedWithUserNotification object:nil];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"contactsLinkedWithUser"]) {
        return;
    }
    
    [self loadObjects];
}

- (void)viewDidUnload {
    [self setSections:nil];
    [self setSuggestions:nil];
    [self setContacts:nil];
    
    [super viewDidUnload];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCContactsLinkedWithUserNotification object:nil];
}

@end
