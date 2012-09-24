//
//  GCFriendsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-14.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCFriendsViewController.h"
#import "GCFriendTableViewCell.h"
#import "UIColor+GCColors.h"
#import "Constants.h"
#import "PFUser+GCAdditions.h"
#import "PFUser+GCUser.h"
#import "AppDelegate.h"

@interface GCFriendsViewController ()

@property (strong, nonatomic) NSMutableArray *friends;

- (void)didTapAddButton;
- (void)fetchFriends;
- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeLeftBarButtonItem;
- (void)customizeTabBarItem;
- (void)customizeTableView;
- (void)customizeEmptyView;

@end

@implementation GCFriendsViewController

#pragma mark - GCFriendsViewController

- (NSMutableArray *)friends {
    if (!_friends) {
        _friends = [NSMutableArray new];
    }
    
    return _friends;
}

- (IBAction)didTapEmptyViewButton {
    [self performSegueWithIdentifier:GCAddFriendSegueIdentifier sender:self];
}

- (void)didTapAddButton {
    [self performSegueWithIdentifier:GCAddFriendSegueIdentifier sender:self];
}

- (void)fetchFriends {    
    [SVProgressHUD show];
    
    [[PFUser currentUser] findFriendsInBackgroundWithBlock:^(NSArray *friends, NSError *error) {
        if (!friends) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve friends", nil)];
            return;
        }

        self.showsEmptyView = friends.count < 1;

        [self.friends removeAllObjects];
        [self.friends addObjectsFromArray:friends];

        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    BOOL hasFriends = self.friends.count > 0;
    
    if (!isReachable) {
        [self setEditing:NO animated:YES];
    }
    
    self.editButtonItem.enabled = hasFriends && isReachable;
    self.navigationItem.rightBarButtonItem.enabled = isReachable;
    self.emptyViewIconButton.enabled = self.emptyViewLabelButton.enabled = !hasFriends && isReachable;
    
    if (isReachable) {
        [self fetchFriends];
    }
}

- (void)customizeLeftBarButtonItem {
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)customizeTabBarItem {
    UIImage *selectedImage = [UIImage imageNamed:@"friends-selected"];
    UIImage *unselectedImage = [UIImage imageNamed:@"friends-normal"];
    
    self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:0];
    [self.navigationController.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
    [self.navigationController.tabBarItem setImageInsets:UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f)];
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
}

- (void)customizeEmptyView {
    [self.emptyViewIconButton setImage:[UIImage imageNamed:@"empty-friends-icon"] forState:UIControlStateNormal];
    [self.emptyViewLabelButton setTitle:NSLocalizedString(@"Tap to add friends", nil) forState:UIControlStateNormal];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    GCFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PFUser *friend = (PFUser *)[self.friends objectAtIndex:indexPath.row];
    
    cell.friend = friend;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    PFUser *friend = (PFUser *)[self.friends objectAtIndex:indexPath.row];
    
    [self.friends removeObject:friend];
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    
    if (self.friends.count < 1) {
        self.editButtonItem.enabled = NO;
        self.showsEmptyView = YES;
    }
    
    [[PFUser currentUser] removeFriend:friend block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            self.editing = NO;
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to remove friend", nil)];
        }
    }];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.frame.size.width, cell.frame.size.height)];
    
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UIViewController

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    self.navigationItem.rightBarButtonItem.enabled = !editing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeLeftBarButtonItem];
    [self customizeTableView];
    [self customizeEmptyView];
    
    [self fetchFriends];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFriends) name:GCFriendAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFriends) name:GCFriendRemovedNotification object:nil];
}

- (void)viewDidUnload {
    [self setFriends:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    
    [self customizeTabBarItem];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCFriendAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCFriendRemovedNotification object:nil];
}

@end