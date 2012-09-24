//
//  GCTwitterFriendViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-21.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCTwitterFriendViewController.h"
#import "GCTwitterAPIClient.h"
#import "PFUser+GCAdditions.h"
#import "GCAddFriendTableViewCell.h"
#import "GCInviteTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "GCPlainTableViewSectionHeaderView.h"
#import "SVPullToRefresh.h"
#import "Constants.h"

@interface GCTwitterFriendViewController () <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) NSInteger cursor;
@property (assign, nonatomic) NSInteger nextCursor;
@property (strong, nonatomic) NSMutableArray *ids;
@property (assign, nonatomic) NSInteger page;
@property (assign, nonatomic) NSInteger pageCount;
@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSMutableArray *suggestions;
@property (strong, nonatomic) NSMutableArray *friends;

- (IBAction)didTapAddButton:(UIButton *)button forEvent:(UIEvent *)event;
- (IBAction)didTapInviteButton:(UIButton *)button forEvent:(UIEvent *)event;

- (void)fetchNextCursorInBackgroundWithBlock:(void (^)(NSArray *ids, NSError *error))block;
- (NSRange)rangeForPage:(NSInteger)page;
- (void)fetchNextPageInBackgroundWithBlock:(void (^)(NSArray *friends, NSError *error))block;
- (void)loadObjects;

@end

@implementation GCTwitterFriendViewController

#pragma mark - GCTwitterFriendViewController

- (NSMutableArray *)ids {
    if (!_ids) {
        _ids = [NSMutableArray new];
    }
    
    return _ids;
}

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
    NSString *screenName = [friend valueForKeyPath:@"screen_name"];
    
    if (![TWTweetComposeViewController canSendTweet]) {
        return;
    }
    
    TWTweetComposeViewController *tweetComposeViewController = [[TWTweetComposeViewController alloc] init];
    NSString *invitation = [NSString stringWithFormat:NSLocalizedString(@"@%@, you should join GameCall, the best way to notify your friends with your game plans, or keep up with theirs.", nil), screenName];
    
    [tweetComposeViewController setInitialText:invitation];
    [tweetComposeViewController addImage:[UIImage imageNamed:@"logo"]];
    [tweetComposeViewController addURL:[NSURL URLWithString:@"http://bit.ly/QlFhod"]];
    
    [self presentModalViewController:tweetComposeViewController animated:YES];
}

- (void)fetchNextCursorInBackgroundWithBlock:(void (^)(NSArray *ids, NSError *error))block {        
    [[GCTwitterAPIClient sharedClient] friendIdsWithCursor:self.cursor block:^(NSArray *ids, NSInteger nextCursor, NSError *error) {
        if (!ids) {
            if (block) {
                block(nil, error);
            }
            
            return;
        }
        
        self.cursor = self.nextCursor;
        self.nextCursor = nextCursor;
        
        if (block) {
            block(ids, nil);
        }
    }];
}

- (NSRange)rangeForPage:(NSInteger)page {
    return NSMakeRange(page * GCTwitterAPIClientUserLookupMaximum, MIN(self.ids.count - (page * GCTwitterAPIClientUserLookupMaximum), GCTwitterAPIClientUserLookupMaximum));
}

- (void)fetchNextPageInBackgroundWithBlock:(void (^)(NSArray *friends, NSError *error))block {
    self.page += 1;
    
    if (self.page >= self.pageCount) {
        if (self.cursor >= self.nextCursor) {
            return;
        }
                
        [self fetchNextCursorInBackgroundWithBlock:^(NSArray *ids, NSError *error) {
            if (!ids) {
                if (block) {
                    block(nil, error);
                }
                
                return;
            }
            
            [self.ids addObjectsFromArray:ids];
            
            self.pageCount = (self.ids.count / GCTwitterAPIClientUserLookupMaximum) + 1;
            
            ids = [ids subarrayWithRange:[self rangeForPage:self.page]];
            
            [[GCTwitterAPIClient sharedClient] lookupUsersWithIds:ids block:^(NSArray *users, NSError *error) {
                if (!users) {
                    block(nil, error);
                    return;
                }
                
                if (block) {
                    block(users, nil);
                }
            }];
        }];
        
        return;
    }
    
    NSArray *ids = [self.ids subarrayWithRange:[self rangeForPage:self.page]];
    
    [[GCTwitterAPIClient sharedClient] lookupUsersWithIds:ids block:^(NSArray *users, NSError *error) {
        if (!users) {
            block(nil, error);
            return;
        }
        
        if (block) {
            block(users, nil);
        }
    }];
}

- (void)loadObjects {
    [SVProgressHUD show];
    
    [self fetchNextPageInBackgroundWithBlock:^(NSArray *twitters, NSError *error) {
        if (!twitters || twitters.count < 1) {
            TFLog(@"%@", error);
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve friends", nil)];
            return;
        }
        
        BOOL isFirstLoad = self.friends.count < 1;
        
        if (isFirstLoad) {
            [self.sections addObject:self.friends];
        }
        
        [self.friends addObjectsFromArray:twitters];
        
        NSIndexSet *friendsIndexSet = [self.sections indexesOfObjectsPassingTest:^BOOL(NSMutableArray *section, NSUInteger idx, BOOL *stop) {
            return section == self.friends;
        }];
        
        [self.tableView beginUpdates];
        
        if (isFirstLoad) {
            [self.tableView insertSections:friendsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [self.tableView reloadSections:friendsIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [self.tableView endUpdates];
        
        [SVProgressHUD dismiss];
        
        self.tableView.showsInfiniteScrolling = self.cursor < self.nextCursor || self.page < self.pageCount - 1;

        [[PFUser currentUser] friendsWithBlock:^(NSArray *friends, NSError *error) {
            if (!friends) {
                return;
            }
            
            NSMutableArray *ids = [NSMutableArray new];
            PFQuery *query = [PFUser query];
            
            for (NSNumber *twId in [twitters valueForKeyPath:@"id"]) {
                [ids addObject:[twId stringValue]];
            }
            
            [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
            [query whereKey:@"objectId" notContainedIn:[friends valueForKeyPath:@"objectId"]];
            [query whereKey:@"twId" containedIn:ids];
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
                            NSString *twId = [(NSNumber *)[friend valueForKeyPath:@"id"] stringValue];
                            
                            if ([suggestion[@"twId"] isEqualToString:twId]) {
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
                        
                        self.tableView.showsInfiniteScrolling = self.cursor < self.nextCursor && self.page < self.pageCount;
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
    NSString *imageURLString = [friend valueForKeyPath:@"profile_image_url"];
    
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
    
    self.cursor = -1;
    self.nextCursor = 0;
    self.page = -1;
    self.pageCount = 0;
    
    __weak __typeof(&*self)weakSelf = self;
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf loadObjects];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:GCTwitterLinkedWithUserNotification object:nil];
    
    if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }
    
    [self loadObjects];
}

- (void)viewDidUnload {
    [self setIds:nil];
    [self setSections:nil];
    [self setSuggestions:nil];
    [self setFriends:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCTwitterLinkedWithUserNotification object:nil];
}

@end
