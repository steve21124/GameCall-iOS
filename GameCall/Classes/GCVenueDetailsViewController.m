//
//  GCVenueDetailsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-05.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCVenueDetailsViewController.h"
#import "GCPointAnnotation.h"
#import "UIColor+GCColors.h"
#import "Constants.h"
#import "TTTAttributedLabel.h"
#import "AppDelegate.h"
#import "JDGroupedFlipNumberView.h"
#import "GCVenue.h"
#import "PFUser+GCUser.h"

@interface GCVenueDetailsViewController () <UITableViewDelegate, TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *fauxSections;
@property (weak, nonatomic) IBOutlet UITableViewCell *activityCell;
@property (strong, nonatomic) JDGroupedFlipNumberView *activityGroupedFlipNumberView;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *phoneLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *websiteLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *addressLabel;

- (IBAction)didTapFavoriteButton:(UIButton *)button;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeTableView;
- (void)customizeNameLabel;
- (void)customizeFavoriteButton;
- (void)customizeFauxSections;
- (void)customizeActivityLabel;
- (void)customizePhoneLabel;
- (void)customizeWebsiteLabel;
- (void)customizeAddressLabel;

@end

@implementation GCVenueDetailsViewController

#pragma mark - GCVenueDetailsViewController

- (JDGroupedFlipNumberView *)activityGroupedFlipNumberView {
    if (!_activityGroupedFlipNumberView) {
        _activityGroupedFlipNumberView = [[JDGroupedFlipNumberView alloc] init];
        _activityGroupedFlipNumberView.intValue = 0;
    }
    
    return _activityGroupedFlipNumberView;
}

- (IBAction)didTapFavoriteButton:(UIButton *)button {
    button.selected = !button.selected;
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating favorites...", nil)];
    
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
        
        [venue saveEventually:^(BOOL succeeded, NSError *error) {
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
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.favoriteButton.enabled = isReachable;
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

- (void)customizeNameLabel {
    NSString *name = [self.annotation.details valueForKeyPath:@"name"];

    self.nameLabel.text = name ? name : [self.annotation.details valueForKeyPath:@"formatted_address"];
}

- (void)customizeFavoriteButton {
    PFRelation *relation = [[PFUser currentUser] relationforKey:@"favorites"];
    PFQuery *query = relation.query;
    
    query.className = @"Venue";
    [query whereKey:@"address" equalTo:[self.annotation.details valueForKeyPath:@"formatted_address"]];
    
    if (query.hasCachedResult) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [query countObjectsInBackgroundWithBlock:^(int matches, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve favorites", nil)];
            return;
        }
        
        self.favoriteButton.selected = matches > 0;
        self.favoriteButton.enabled = YES;
    }];
}

- (void)customizeFauxSections {
    for (UIView *fauxSection in self.fauxSections) {
        fauxSection.backgroundColor = [UIColor blackTranslucentColor];
        fauxSection.layer.borderWidth = 1.f;
        fauxSection.layer.borderColor = [UIColor offWhiteColor].CGColor;
        fauxSection.layer.cornerRadius = 10.f;
    }
}

- (void)customizeActivityLabel {    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {        
        PFQuery *venuesQuery = [PFQuery queryWithClassName:@"Venue"];
        NSError *errorMatchingVenue;
        
        [venuesQuery whereKey:@"address" equalTo:[self.annotation.details valueForKeyPath:@"formatted_address"]];
        
        if (venuesQuery.hasCachedResult) {
            venuesQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        }
        
        PFObject *venue = [venuesQuery getFirstObject:&errorMatchingVenue];
        
        if (!venue) {
            if (errorMatchingVenue.code != kPFErrorObjectNotFound) {
                TFLog(@"%@", errorMatchingVenue);
            }
            
            return;
        }
        
        PFRelation *venueGamesRelation = [venue relationforKey:@"games"];
        PFQuery *venueGamesQuery = venueGamesRelation.query;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
        
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        
        NSDate *minDate = [calendar dateFromComponents:components];
        
        components.hour = 23;
        components.minute = 59;
        components.second = 59;
        
        NSDate *maxDate = [calendar dateFromComponents:components];
        
        venueGamesQuery.className = @"Game";
        [venueGamesQuery whereKey:@"date" greaterThanOrEqualTo:minDate];
        [venueGamesQuery whereKey:@"date" lessThanOrEqualTo:maxDate];
        
        [venueGamesQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
            if (error) {
                TFLog(@"%@", error);
                return;
            }
            
            [self.activityGroupedFlipNumberView animateToValue:count withDuration:1.0];
        }];
    });
}

- (void)customizePhoneLabel {
    self.phoneLabel.linkAttributes = @{ @"NSForegroundColorAttributeName" : [UIColor offWhiteColor] };
    self.phoneLabel.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
    self.phoneLabel.delegate = self;
    
    NSString *phoneNumber = [self.annotation.details valueForKeyPath:@"formatted_phone_number"];
    NSString *text = phoneNumber ? phoneNumber : NSLocalizedString(@"Unavailable", nil);
    
    self.phoneLabel.text = text;
}

- (void)customizeWebsiteLabel {
    self.websiteLabel.linkAttributes = @{ @"NSForegroundColorAttributeName" : [UIColor offWhiteColor] };
    self.websiteLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    self.websiteLabel.delegate = self;
    
    NSString *website = [self.annotation.details valueForKeyPath:@"url"];
    NSString *text = website ? website : NSLocalizedString(@"Unavailable", nil);
    
    self.websiteLabel.text = text;
}

- (void)customizeAddressLabel {
    self.addressLabel.linkAttributes = @{ @"NSForegroundColorAttributeName" : [UIColor offWhiteColor] };
    self.addressLabel.dataDetectorTypes = UIDataDetectorTypeAddress;
    self.addressLabel.delegate = self;
    
    NSString *address = [self.annotation.details valueForKeyPath:@"formatted_address"];
    NSString *text = address ? address : NSLocalizedString(@"Unavailable", nil);
    
    self.addressLabel.text = text;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]];
    
    [[UIApplication sharedApplication] openURL:url];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
    NSString *address = [ABCreateStringWithAddressDictionary(addressComponents, YES) stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", address]];
    
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    [self customizeNameLabel];
    [self customizeFavoriteButton];
    [self customizeFauxSections];
    [self customizeActivityLabel];
    [self customizePhoneLabel];
    [self customizeWebsiteLabel];
    [self customizeAddressLabel];
    
    [self.activityCell addSubview:self.activityGroupedFlipNumberView];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setAnnotation:nil];
    [self setNameLabel:nil];
    [self setFavoriteButton:nil];
    [self setFauxSections:nil];
    [self setActivityCell:nil];
    [self setActivityGroupedFlipNumberView:nil];
    [self setPhoneLabel:nil];
    [self setWebsiteLabel:nil];
    [self setAddressLabel:nil];

    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.activityGroupedFlipNumberView.frame = CGRectMake(20.f, 10.f, 64.f, 64.f);
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
