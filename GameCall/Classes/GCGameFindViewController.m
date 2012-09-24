//
//  GCGameFindViewController.m
//  GameCall
//
//
//  Created by Nik Macintosh on 12-07-07.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGameFindViewController.h"
#import "GCGameDetailsViewController.h"
#import "UIColor+GCColors.h"
#import "GCGameTableViewCell.h"
#import "SVPullToRefresh.h"
#import "PFUser+GCAdditions.h"
#import "GCPlainTableViewSectionHeaderView.h"

static NSString * const GCDiscloseGameDetailsSegueIdentifier = @"GCDiscloseGameDetailsSegue";

@interface GCGameFindViewController ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSMutableDictionary *sections;
@property (strong, nonatomic) NSArray *headerTitles;

- (void)fetchGames;
- (void)reachabilityDidChange:(NSNotification *)notification;

- (void)customizeTableView;

@end

@implementation GCGameFindViewController

#pragma mark - GCGameFindViewController

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

- (void)fetchGames {
    [SVProgressHUD show];
    
    [[PFUser currentUser] suggestedGamesWithBlock:^(NSArray *games, NSError *error) {
        if (!games) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve games", nil)];
            [self.tableView.pullToRefreshView stopAnimating];
            return;
        }
        
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
        
        self.headerTitles = [self.sections.allKeys sortedArrayUsingSelector:@selector(compare:)];
        
        [self.tableView reloadData];
        [self.tableView.pullToRefreshView stopAnimating];
        [SVProgressHUD dismiss];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    if (isReachable) {
        [self.tableView.pullToRefreshView triggerRefresh];
    }
}

- (void)customizeTableView {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    __weak __typeof(&*self)weakSelf = self;
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.pullToRefreshView.textColor = [UIColor offBlackColor];
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf fetchGames];
    }];
    
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
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
    
    return cell;
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
    return 64.f;
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
    
    [self performSegueWithIdentifier:GCDiscloseGameDetailsSegueIdentifier sender:game];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setDateFormatter:nil];
    [self setSections:nil];
    [self setHeaderTitles:nil];
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView.pullToRefreshView triggerRefresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(PFObject *)game {
    if (![segue.identifier isEqualToString:GCDiscloseGameDetailsSegueIdentifier]) {
        return;
    }
    
    [(GCGameDetailsViewController *)segue.destinationViewController setGame:game];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
