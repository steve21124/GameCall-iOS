//
//  GCMyGamesViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-16.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCMyGamesViewController.h"
#import "Constants.h"
#import "UIColor+GCColors.h"
#import "GCGameTableViewCell.h"
#import "GCGameDetailsViewController.h"
#import "PFUser+GCAdditions.h"
#import "AppDelegate.h"
#import "GCPlainTableViewSectionHeaderView.h"
#import "SVPullToRefresh.h"

static NSString * const kGCGameCallSegueIdentifier = @"GCGameCallSegue";
static NSString * const kGCDiscloseGameDetailsSegueIdentifier = @"GCDiscloseGameDetailsSegue";

@interface GCMyGamesViewController ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableDictionary *sections;
@property (strong, nonatomic) NSMutableArray *headerTitles;
@property (strong, nonatomic) NSMutableArray *playerCounts;

- (void)didTapAddButton;
- (void)fetchGames;
- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeLeftBarButtonItem;
- (void)customizeTableView;
- (void)customizeEmptyView;

@end

@implementation GCMyGamesViewController

#pragma mark - GCMyGamesViewController

- (UIBarButtonItem *)addButtonItem {
    if (!_addButtonItem) {
        _addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAddButton)];
    }
    
    return _addButtonItem;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    
    return _dateFormatter;
}

- (NSMutableDictionary *)sections {
    if (!_sections) {
        _sections = [NSMutableDictionary dictionary];
    }
    
    return _sections;
}

- (NSMutableArray *)headerTitles {
    if (!_headerTitles) {
        _headerTitles = [NSMutableArray new];
    }
    
    return _headerTitles;
}

- (NSMutableArray *)playerCounts {
    if (!_playerCounts) {
        _playerCounts = [NSMutableArray new];
    }
    
    return _playerCounts;
}

- (void)didTapAddButton {
    [self performSegueWithIdentifier:kGCGameCallSegueIdentifier sender:self];
}

- (IBAction)didTapEmptyViewButton {
    [self didTapAddButton];
}

- (void)fetchGames {
    [[PFUser currentUser] myGamesWithBlock:^(NSArray *games, NSError *error) {
        if (!games) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve games", nil)];
            return;
        }
        
        self.showsEmptyView = games.count < 1;

        [self.sections removeAllObjects];

        for (PFObject *game in games) {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[game objectForKey:@"date"]];
            NSDate *date = [calendar dateFromComponents:components];
            NSMutableArray *rows = [self.sections objectForKey:date];

            if (!rows) {
                rows = [NSMutableArray array];

                [self.sections setObject:rows forKey:date];
            }

            [rows addObject:game];
        }

        [self.headerTitles removeAllObjects];
        [self.headerTitles addObjectsFromArray:[self.sections.allKeys sortedArrayUsingSelector:@selector(compare:)]];
        
        [self.tableView reloadData];
        [self.tableView.pullToRefreshView stopAnimating];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    BOOL hasGames = self.sections.count > 0;
    
    if (reachability.currentReachabilityStatus == NotReachable) {
        [self setEditing:NO animated:YES];
    }
    
    self.editButtonItem.enabled = hasGames && isReachable;
    self.addButtonItem.enabled = isReachable;
    self.emptyViewIconButton.enabled = self.emptyViewLabelButton.enabled = !hasGames && isReachable;
    
    if (isReachable) {
        [self.tableView.pullToRefreshView triggerRefresh];
    }
}

- (void)customizeLeftBarButtonItem {
    self.editButtonItem.enabled = NO;
}

- (void)customizeTableView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
}

- (void)customizeEmptyView {
    [self.emptyViewIconButton setImage:[UIImage imageNamed:@"trihex-background"] forState:UIControlStateNormal];
    [self.emptyViewLabelButton setTitle:NSLocalizedString(@"Tap to call a game", nil) forState:UIControlStateNormal];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDate *date = [self.headerTitles objectAtIndex:section];
    
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    return [self.dateFormatter stringFromDate:date];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDate *date = [self.headerTitles objectAtIndex:section];
    NSMutableArray *rows = [self.sections objectForKey:date];
    
    return rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    GCGameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSDate *date = [self.headerTitles objectAtIndex:indexPath.section];
    NSMutableArray *section = [self.sections objectForKey:date];
    PFObject *game = [section objectAtIndex:indexPath.row];
    
    self.dateFormatter.dateStyle = NSDateFormatterNoStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    cell.game = game;
    cell.detailsLabel.text = [NSString stringWithFormat:@"@ %@", [self.dateFormatter stringFromDate:[game objectForKey:@"date"]]];
    
    PFRelation *playersRelation = [game relationforKey:@"players"];
    PFQuery *playersQuery = playersRelation.query;
    
    playersQuery.className = @"_User";
    
    [playersQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        cell.detailsLabel.text = [cell.detailsLabel.text stringByAppendingFormat:NSLocalizedString(@" with %i players", nil), count];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    NSDate *date = [self.headerTitles objectAtIndex:indexPath.section];
    NSMutableArray *section = [self.sections objectForKey:date];
    PFObject *game = [section objectAtIndex:indexPath.row];
    
    [section removeObject:game];
    
    if (section.count == 0) {
        [self.headerTitles removeObject:date];
        [self.sections removeObjectForKey:date];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    if (self.sections.count < 1) {
        self.editButtonItem.enabled = NO;
        self.showsEmptyView = YES;
    }
    
    // Remove from my games
    PFRelation *myGamesRelation = [[PFUser currentUser] relationforKey:@"games"];
    
    [myGamesRelation removeObject:game];
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        if (error) {
            TFLog(@"%@", error);
            return;
        }
        
        [self.tableView.pullToRefreshView triggerRefresh];
    }];
    
    // Remove me as a player in this game
    PFRelation *gamePlayers = [game relationforKey:@"players"];
    
    [gamePlayers removeObject:[PFUser currentUser]];
    [game saveEventually];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {    
    GCPlainTableViewSectionHeaderView *view = [[GCPlainTableViewSectionHeaderView alloc] init];
    
    view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    return view;
}

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
    
    NSDate *date = [self.headerTitles objectAtIndex:indexPath.section];
    NSMutableArray *section = [self.sections objectForKey:date];
    PFObject *game = [section objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:kGCDiscloseGameDetailsSegueIdentifier sender:game];
}

#pragma mark - UIViewController

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    self.addButtonItem.enabled = !editing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeLeftBarButtonItem];
    [self customizeTableView];
    [self customizeEmptyView];
    
    __weak __typeof(&*self)weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf fetchGames];
    }];
    
    [self.tableView.pullToRefreshView triggerRefresh];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchGames) name:GCGameAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchGames) name:GCGameRemovedNotification object:nil];
}

- (void)viewDidUnload {
    [self setAddButtonItem:nil];
    [self setDateFormatter:nil];
    [self setSections:nil];
    [self setHeaderTitles:nil];
    [self setPlayerCounts:nil];
    
    [super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.editing = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(PFObject *)game {
    if ([segue.identifier isEqualToString:kGCGameCallSegueIdentifier]) {
        return;
    }
    
    [(GCGameDetailsViewController *)segue.destinationViewController setGame:game];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCGameAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCGameRemovedNotification object:nil];
}

@end
