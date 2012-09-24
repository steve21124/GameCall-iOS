//
//  GCPlayersViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-24.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCPlayersViewController.h"
#import "GCFriendTableViewCell.h"

@interface GCPlayersViewController ()

@property (strong, nonatomic) NSArray *players;

- (void)fetchPlayers;
- (void)reachabilityDidChange:(NSNotification *)notification;

- (void)customizeTableView;

@end

@implementation GCPlayersViewController

#pragma mark - GCPlayersViewController

- (NSArray *)players {
    if (!_players) {
        _players = [NSArray new];
    }
    
    return _players;
}

- (void)fetchPlayers {
    PFRelation *playersRelation = [self.game relationforKey:@"players"];
    PFQuery *playersQuery = playersRelation.query;
    
    playersQuery.className = @"_User";
    [playersQuery orderByAscending:@"lastName"];
    
    if (self.players.count < 1 && playersQuery.hasCachedResult) {
        playersQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [SVProgressHUD show];
    
    [playersQuery findObjectsInBackgroundWithBlock:^(NSArray *players, NSError *error) {
        if (!players) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve players", nil)];
            return;
        }
        
        self.players = players;
        
        [self.tableView reloadData];
        [SVProgressHUD dismiss];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    if (isReachable) {
        [self fetchPlayers];
    }
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.tableView.tableFooterView = tableFooterView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.players.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    GCFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PFUser *player = [self.players objectAtIndex:indexPath.row];
    
    cell.friend = player;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.f;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    [self fetchPlayers];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setGame:nil];
    [self setPlayers:nil];
    
    [super viewDidUnload];
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
