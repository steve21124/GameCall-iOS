//
//  GCNearbyViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-28.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCNearbyViewController.h"
#import "GCGoogleMapsAPIClient.h"
#import "GCPointAnnotation.h"
#import "GCPinAnnotationView.h"
#import "GCVenueDetailsViewController.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "GCVenue.h"
#import "PFUser+GCUser.h"

static NSString * const kGCDiscloseVenueDetailsSegueIdentifier = @"GCDiscloseVenueDetailsSegue";

@interface GCNearbyViewController () <UISearchDisplayDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (assign, nonatomic) BOOL isLoading;
@property (assign, nonatomic) BOOL isDirty;
@property (strong, nonatomic) NSArray *searchResults;

- (IBAction)didTapSearchButton:(UIBarButtonItem *)button;

- (void)didLongPressMapView:(UILongPressGestureRecognizer *)recognizer;
- (void)loadPredictions;
- (void)addAnnotationFromNotification:(NSNotification *)notification;
- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeTabBarItem;

@end

@implementation GCNearbyViewController

#pragma mark - GCNearbyViewController

- (void)setAnnotation:(GCPointAnnotation *)annotation {
    _annotation = annotation;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:annotation];
    [self.mapView performSelector:@selector(selectAnnotation:animated:) withObject:annotation afterDelay:0.65];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 5000.0, 5000.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    
    [self.mapView setRegion:adjustedRegion animated:YES];
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        
        _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    
    return _geocoder;
}

- (NSArray *)searchResults {
    if (!_searchResults) {
        _searchResults = [NSArray array];
    }
    
    return _searchResults;
}

- (IBAction)didTapSearchButton:(UIBarButtonItem *)button {    
    [UIView animateWithDuration:0.25 animations:^{
        self.searchDisplayController.searchBar.alpha = 1.f;
    
    } completion:^(BOOL finished) {
        [self.searchDisplayController.searchBar becomeFirstResponder];
    }];
}

- (void)didLongPressMapView:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint point = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    [[GCGoogleMapsAPIClient sharedClient] reverseGeocodeCoordinate:coordinate block:^(NSArray *results, NSError *error) {        
        if (!results) {
            TFLog(@"%@", error);
            return;
        }
        
        GCPointAnnotation *annotation = [[GCPointAnnotation alloc] init];
        
        annotation.details = [results objectAtIndex:0];
        annotation.coordinate = coordinate;
        
        self.annotation = annotation;
    }];
}

- (void)loadPredictions {
    NSString *input = self.searchDisplayController.searchBar.text;
    
    self.isLoading = YES;
    
    [[GCGoogleMapsAPIClient sharedClient] predictionswithInput:input block:^(NSArray *predictions, NSError *error) {
        if (!predictions || error) {
            TFLog(@"%@", error);
            
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

- (void)addAnnotationFromNotification:(NSNotification *)notification {
    GCPointAnnotation *annotation = [notification.userInfo objectForKey:@"annotation"];
    
    self.annotation = annotation;
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.navigationItem.leftBarButtonItem.enabled = self.navigationItem.rightBarButtonItem.enabled = isReachable;
}

- (void)customizeTabBarItem {
    UIImage *selectedImage = [UIImage imageNamed:@"nearby-selected"];
    UIImage *unselectedImage = [UIImage imageNamed:@"nearby-normal"];
    
    self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:0];
    [self.navigationController.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
    [self.navigationController.tabBarItem setImageInsets:UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f)];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return NO;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {    
    [UIView animateWithDuration:0.25 animations:^{
        self.searchDisplayController.searchBar.alpha = 0.f;
    }];
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
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSDictionary *attributes = [self.searchResults objectAtIndex:indexPath.row];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [attributes valueForKeyPath:@"description"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSDictionary *prediction = [self.searchResults objectAtIndex:indexPath.row];
    NSString *reference = [prediction valueForKeyPath:@"reference"];
    
    [[GCGoogleMapsAPIClient sharedClient] detailsWithReference:reference block:^(NSDictionary *details, NSError *error) {
        if (!details) {
            TFLog(@"%@", error);
            return;
        }
        
        GCPointAnnotation *annotation = [[GCPointAnnotation alloc] init];
        
        annotation.details = details;
        
        [self.searchDisplayController setActive:NO animated:NO];
        self.searchDisplayController.searchBar.alpha = 0.f;
        
        self.annotation = annotation;
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (!newLocation || self.annotation) {
        return;
    }
    
    [self.locationManager stopUpdatingLocation];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 5000.0, 5000.0);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    
    [self.mapView setRegion:adjustedRegion animated:YES];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    if ([annotation isKindOfClass:[GCPointAnnotation class]]) {
        static NSString *PointAnnotationViewIdentifier = @"Point";
        GCPinAnnotationView *pinAnnotationView = (GCPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:PointAnnotationViewIdentifier];
        
        if (!pinAnnotationView) {
            pinAnnotationView = [[GCPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PointAnnotationViewIdentifier];
        } else {
            pinAnnotationView.annotation = annotation;
        }
        
        return pinAnnotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIButton *)button {
    if (button.buttonType == UIButtonTypeCustom) {
        button.selected = !button.selected;
                
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating favorites", nil)];
        
        NSString *address = [self.annotation.details valueForKeyPath:@"formatted_address"];
        
        [GCVenue getVenueWithAddress:address inBackgroundWithBlock:^(PFObject *venue, NSError *error) {
            if (!venue && error.code != kPFErrorObjectNotFound) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to update favorites", nil)];
                return;
            }
            
            if (!button.selected) {
                [[PFUser currentUser] removeFavorite:venue eventually:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to remove favorite", nil)];
                        return;
                    }

                    [[NSNotificationCenter defaultCenter] postNotificationName:GCFavoriteRemovedNotification object:nil];
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Favorite removed", nil)];
                }];
                
                return;
            }
            
            if (!venue) {
                venue = [[GCVenue alloc] initWithAnnotation:self.annotation];
            }
            
            [venue saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to save as new venue", nil)];
                    return;
                }
                
                [[PFUser currentUser] addFavorite:venue eventually:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add favorite", nil)];
                        return;
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GCFavoriteAddedNotification object:nil];
                    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Favorite added", nil)];
                }];
            }];
        }];
        
        return;
    }
    
    [self performSegueWithIdentifier:kGCDiscloseVenueDetailsSegueIdentifier sender:view.annotation];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    
    [self.locationManager startUpdatingLocation];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressMapView:)];
    
    [self.mapView addGestureRecognizer:longPressGestureRecognizer];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addAnnotationFromNotification:) name:GCAnnotationAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setAnnotation:nil];
    [self setLocationManager:nil];
    [self setGeocoder:nil];
    [self setMapView:nil];
    [self setSearchResults:nil];
    
    [super viewDidUnload];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCAnnotationAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
