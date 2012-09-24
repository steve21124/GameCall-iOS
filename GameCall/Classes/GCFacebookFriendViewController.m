//
//  GCFacebookFriendViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-21.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCFacebookFriendViewController.h"
#import "PFUser+GCAdditions.h"
#import "GCPlainTableViewSectionHeaderView.h"
#import "GCAddFriendTableViewCell.h"
#import "GCInviteTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "Constants.h"

@interface GCFacebookFriendViewController ()

@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *suggestions;
@property (strong, nonatomic) NSMutableArray *friends;

- (IBAction)didTapAddButton:(UIButton *)button forEvent:(UIEvent *)event;
- (IBAction)didTapInviteButton:(UIButton *)button forEvent:(UIEvent *)event;
- (void)loadObjects;

@end

@implementation GCFacebookFriendViewController

#pragma mark - GCFacebookFriendViewController

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

- (NSMutableArray *)friends {
    if (!_friends) {
        _friends = [NSMutableArray new];
    }
    
    return _friends;
}

- (IBAction)didTapAddButton:(UIButton *)button forEvent:(UIEvent *)event {
    UITouch *touch = [event touchesForView:button].anyObject;
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    PFUser *user = [self.suggestions objectAtIndex:indexPath.row];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Adding friend", nil)];
    
    [[PFUser currentUser] addFriend:user block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add friend", nil)];
            return;
        }
        
        [self.suggestions removeObject:user];
        
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
    
    NSDictionary *friend = [self.friends objectAtIndex:indexPath.row];

    NSString *fbId = [friend valueForKeyPath:@"id"];
    NSString *name = [friend valueForKeyPath:@"name"];
    NSString *link = @"http://www.gamecall.me/download";
    NSString *picture = @"http://www.gamecall.me/img/logo-social.png";
    NSString *linkName = @"GameCall Social Sports";
    NSString *caption = [NSString stringWithFormat:NSLocalizedString(@"%@, you should join GameCall, the best way to notify your friends with your game plans, or keep up with theirs.", nil), name];
    NSDictionary *properties = @{
    @"Homepage" : @{ @"text" : @"Visit", @"href" : @"http://www.gamecall.me" },
    @"Facebook" : @{ @"text" : @"Visit", @"href" : @"http://www.facebook.com/GameCall" },
    @"Twitter" : @{ @"text" : @"Visit", @"href" : @"http://www.twitter.com/GameCallApp" }
    };
    NSData *propertiesData = [NSJSONSerialization dataWithJSONObject:properties options:kNilOptions error:nil];
    
    NSDictionary *params = @{ @"to" : fbId, @"link" : link, @"picture" : picture, @"name": linkName, @"caption" : caption, @"properties" : [[NSString alloc] initWithData:propertiesData encoding:NSUTF8StringEncoding] };
        
    [[PFFacebookUtils facebook] dialog:@"feed" andParams:[NSMutableDictionary dictionaryWithDictionary:params] andDelegate:nil];
}

- (void)loadObjects {
    [SVProgressHUD show];
    
    PF_FBRequest *request = [PF_FBRequest requestForMyFriends];
    
    [request startWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"last_name" ascending:YES selector:@selector(localizedStandardCompare:)];
        NSArray *facebooks = [(NSArray *)[result valueForKeyPath:@"data"] sortedArrayUsingDescriptors:@[ descriptor ]];
        
        if (!facebooks || facebooks.count < 1) {
            TFLog(@"%@", error);
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve friends", nil)];
            return;
        }

        [self.friends removeAllObjects];
        [self.friends addObjectsFromArray:facebooks];
        [self.sections removeAllObjects];
        [self.sections addObject:self.friends];

        NSIndexSet *friendsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
            return section == self.friends;
        }];

        [self.tableView beginUpdates];
        [self.tableView insertSections:friendsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [SVProgressHUD dismiss];

        [[PFUser currentUser] friendsWithBlock:^(NSArray *friends, NSError *error) {
            if (!friends) {
                [SVProgressHUD dismiss];
                return;
            }

            NSArray *ids = [facebooks valueForKeyPath:@"id"];
            PFQuery *query = [PFUser query];

            [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
            [query whereKey:@"objectId" notContainedIn:[friends valueForKeyPath:@"objectId"]];
            [query whereKey:@"fbId" containedIn:ids];
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
                    NSIndexSet *friendsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
                        return section == self.friends;
                    }];
                    NSMutableArray *duplicates = [NSMutableArray new];
                    NSMutableArray *indexPaths = [NSMutableArray new];

                    for (PFUser *suggestion in self.suggestions) {
                        for (NSDictionary *friend in self.friends) {
                            if ([suggestion[@"fbId"] isEqualToString:[friend valueForKeyPath:@"id"]]) {
                                NSUInteger section = friendsIndexSet.firstIndex;
                                NSUInteger row = [self.friends indexOfObject:friend];
                                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

                                [duplicates addObject:friend];
                                [indexPaths addObject:indexPath];
                            }
                        }
                    }

                    [self.friends removeObjectsInArray:duplicates];

                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        if (self.friends.count < 1) {
                            [self.sections removeObject:self.friends];
                            
                            [self.tableView beginUpdates];
                            [self.tableView deleteSections:friendsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
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
    
    CellIdentifier = @"FriendCell";
    GCInviteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSDictionary *friend = [self.friends objectAtIndex:indexPath.row];
    NSString *name = [friend valueForKeyPath:@"name"];
    NSString *imageURLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", [friend valueForKeyPath:@"id"]];
    
    [cell.photoImageView setImageWithURL:[NSURL URLWithString:imageURLString] placeholderImage:[UIImage imageNamed:@"photo-placeholder"]];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:GCFacebookLinkedWithUserNotification object:nil];
    
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }
    
    [self loadObjects];
}

- (void)viewDidUnload {
    [self setSections:nil];
    [self setSuggestions:nil];
    [self setFriends:nil];
    
    [super viewDidUnload];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCFacebookLinkedWithUserNotification object:nil];
}

@end
