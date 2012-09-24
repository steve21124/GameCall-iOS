//
//  GCFavoritesViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-04.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCFavoritesViewController.h"
#import "PFUser+GCAdditions.h"
#import "GCVenueTableViewCell.h"
#import "Constants.h"
#import "UIColor+GCColors.h"
#import "GCGoogleMapsAPIClient.h"
#import "GCPointAnnotation.h"
#import "GCNearbyViewController.h"
#import "AppDelegate.h"
#import "PFUser+GCUser.h"

static NSInteger const kGCNearbyTabIndex = 3;
static NSString * const kGCDiscloseVenueDetailsSegueIdentifier = @"GCDiscloseVenueDetailsSegue";

@interface GCFavoritesViewController () <UISearchDisplayDelegate>

@property (assign, nonatomic) BOOL isLoading;
@property (assign, nonatomic) BOOL isDirty;
@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSMutableArray *favorites;

- (IBAction)didTapAddButton;

- (void)tableView:(UITableView *)tableView discloseDetails:(NSString *)reference;
- (void)loadPredictions;
- (void)fetchFavorites;
- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeLeftBarButtonItem;
- (void)customizeTabBarItem;
- (void)customizeTableView;
- (void)customizeEmptyView;
- (void)postAddAnnotationNotification:(GCPointAnnotation *)annotation;

@end

@implementation GCFavoritesViewController

#pragma mark - GCFavoritesViewController

- (NSArray *)searchResults {
    if (!_searchResults) {
        _searchResults = [NSArray new];
    }
    
    return _searchResults;
}

- (NSMutableArray *)favorites {
    if (!_favorites) {
        _favorites = [NSMutableArray new];
    }
    
    return _favorites;
}

- (IBAction)didTapAddButton {
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)tableView:(UITableView *)tableView discloseDetails:(NSString *)reference {        
    [[GCGoogleMapsAPIClient sharedClient] detailsWithReference:reference block:^(NSDictionary *details, NSError *error) {
        if (!details) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve details", nil)];
            return;
        }
        
        GCPointAnnotation *annotation = [[GCPointAnnotation alloc] init];
        
        annotation.details = details;
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {            
            [self.searchDisplayController setActive:NO animated:NO];
            self.tabBarController.selectedIndex = kGCNearbyTabIndex;
            [self performSelector:@selector(postAddAnnotationNotification:) withObject:annotation afterDelay:0.0];
            
            return;
        }
        
        [self performSegueWithIdentifier:kGCDiscloseVenueDetailsSegueIdentifier sender:annotation];
    }];
}

- (IBAction)didTapEmptyViewButton {
    [self didTapAddButton];
}

- (void)loadPredictions {
    NSString *input = self.searchDisplayController.searchBar.text;
    
    self.isLoading = YES;
    
    [[GCGoogleMapsAPIClient sharedClient] predictionswithInput:input block:^(NSArray *predictions, NSError *error) {
        if (!predictions) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve predictions", nil)];
            self.isLoading = NO;
            return;
        }
        
        self.searchResults = predictions;
        [self.searchDisplayController.searchResultsTableView reloadData];
        self.isLoading = NO;
        
        if (!self.isDirty) {
            return;
        }
        
        self.isDirty = NO;
        [self loadPredictions];
    }];
}

- (void)fetchFavorites {    
    [SVProgressHUD show];
    
    [[PFUser currentUser] findFavoritesInBackgroundWithBlock:^(NSArray *favorites, NSError *error) {
        if (!favorites) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve favorites", nil)];
            return;
        }
        
        self.showsEmptyView = favorites.count < 1;
        self.tableView.scrollEnabled = favorites.count > 0;
        
        [self.favorites removeAllObjects];
        [self.favorites addObjectsFromArray:favorites];
        
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
    BOOL hasFavorites = self.favorites.count > 0;
    
    if (reachability.currentReachabilityStatus == NotReachable) {
        [self setEditing:NO animated:YES];
        [self.searchDisplayController setActive:NO animated:NO];
    }
    
    self.editButtonItem.enabled = hasFavorites && isReachable;
    self.navigationItem.rightBarButtonItem.enabled = isReachable;
    self.emptyViewIconButton.enabled = self.emptyViewLabelButton.enabled = !hasFavorites && isReachable;
    self.searchDisplayController.searchBar.userInteractionEnabled = isReachable;
    self.searchDisplayController.searchBar.alpha = isReachable ? 1.f : 0.5f;
    
    if (isReachable) {
        [self fetchFavorites];
    }
}

- (void)customizeLeftBarButtonItem {
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)customizeTabBarItem {
    UIImage *selectedImage = [UIImage imageNamed:@"favorites-selected"];
    UIImage *unselectedImage = [UIImage imageNamed:@"favorites-normal"];
    
    self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:0];
    [self.navigationController.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
    [self.navigationController.tabBarItem setImageInsets:UIEdgeInsetsMake(5.0f, 0.0f, -5.0f, 0.0f)];
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
    [self.emptyViewIconButton setImage:[UIImage imageNamed:@"empty-favorites-icon"] forState:UIControlStateNormal];
    [self.emptyViewLabelButton setTitle:NSLocalizedString(@"Tap to add favorites", nil) forState:UIControlStateNormal];
}

- (void)postAddAnnotationNotification:(GCPointAnnotation *)annotation {
    [[NSNotificationCenter defaultCenter] postNotificationName:GCAnnotationAddedNotification object:nil userInfo:@{ @"annotation" : annotation }];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView setContentOffset:CGPointMake(0.f, self.searchDisplayController.searchBar.frame.size.height) animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length < 2) {
        return;
    }
    
    if (self.isLoading) {
        self.isDirty = YES;
        
        return;
    }
    
    [self loadPredictions];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults.count;
    }
    
    return self.favorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        static NSString *CellIdentifier = @"PredictionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        NSDictionary *attributes = [self.searchResults objectAtIndex:indexPath.row];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = [attributes valueForKeyPath:@"description"];
        
        return cell;
    }
    
    static NSString *CellIdentifier = @"Cell";
    GCVenueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PFObject *venue = [self.favorites objectAtIndex:indexPath.row];
    
    cell.venue = venue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    PFObject *favorite = [self.favorites objectAtIndex:indexPath.row];
    
    [[PFUser currentUser] removeFavorite:favorite eventually:^(BOOL succeeded, NSError *error) {
        if (error) {
            TFLog(@"%@", error);
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GCFavoriteRemovedNotification object:nil];
    }];
    
    [self.favorites removeObject:favorite];
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationLeft];
    
    if (self.favorites.count < 1) {
        self.editButtonItem.enabled = NO;
        self.showsEmptyView = YES;
        [self.tableView setContentOffset:CGPointMake(0.f, self.searchDisplayController.searchBar.frame.size.height) animated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (tableView == self.searchDisplayController.searchResultsTableView) ? UITableViewAutomaticDimension : 64.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return;
    }
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.frame.size.width, cell.frame.size.height)];
    
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *reference;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSDictionary *prediction = [self.searchResults objectAtIndex:indexPath.row];
        
        reference = [prediction valueForKeyPath:@"reference"];
    } else {
        PFObject *venue = [self.favorites objectAtIndex:indexPath.row];
        
        reference = [venue valueForKeyPath:@"googlePlacesReference"];
    }
    
    [self tableView:tableView discloseDetails:reference];
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
    
    [self fetchFavorites];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFavorites) name:GCFavoriteAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchFavorites) name:GCFavoriteRemovedNotification object:nil];
}

- (void)viewDidUnload {
    [self setSearchResults:nil];
    [self setFavorites:nil];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    self.tableView.contentOffset = CGPointMake(0.f, self.searchDisplayController.searchBar.frame.size.height);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect frame = self.emptyView.frame;
    frame.origin = CGPointMake(frame.origin.x, frame.origin.y + 44.f);
    self.emptyView.frame = frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(GCPointAnnotation *)annotation {
    [segue.destinationViewController setAnnotation:annotation];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCFavoriteAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCFavoriteRemovedNotification object:nil];
}

@end
