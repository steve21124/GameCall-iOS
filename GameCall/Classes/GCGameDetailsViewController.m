//
//  GCGameDetailsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-08.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGameDetailsViewController.h"
#import "PSActionSheet.h"
#import "UIColor+GCColors.h"
#import "GCImageView.h"
#import "GCPlayersViewController.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "JDGroupedFlipNumberView.h"
#import "GCTwitterAPIClient.h"

static NSString * const GCDisclosePlayerDetailsSegueIdentifier = @"GCDisclosePlayerDetailsSegue";
static double const kGCGameDetailsMapViewRadius = 1000.0;

@interface GCGameDetailsViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *fauxSections;
@property (weak, nonatomic) IBOutlet UITableViewCell *callerCell;
@property (weak, nonatomic) IBOutlet UILabel *callerNameLabel;
@property (weak, nonatomic) IBOutlet GCImageView *callerPhotoImageView;
@property (weak, nonatomic) IBOutlet UITableViewCell *spaceTimeCell;
@property (weak, nonatomic) IBOutlet UIImageView *sportIndicatorImageView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *spaceLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *playersCell;
@property (strong, nonatomic) JDGroupedFlipNumberView *playersGroupedFlipNumberView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *callToActionButtons;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;

- (IBAction)didTapJoinButton:(UIButton *)button;
- (IBAction)didTapQuitButton:(UIButton *)button;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeBackgroundImage;
- (void)customizeFauxSections;
- (void)customizeCallerCell;
- (void)customizeSpaceTimeCell;
- (void)customizePlayersCell;
- (void)customizeMapView;
- (void)customizeCallToActionButtons;

@end

@implementation GCGameDetailsViewController

#pragma mark - GCGameDetailsViewController

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    return _dateFormatter;
}

- (JDGroupedFlipNumberView *)playersGroupedFlipNumberView {
    if (!_playersGroupedFlipNumberView) {
        _playersGroupedFlipNumberView = [[JDGroupedFlipNumberView alloc] initWithFlipNumberViewCount:2];
        _playersGroupedFlipNumberView.intValue = 0;
    }
    
    return _playersGroupedFlipNumberView;
}

- (IBAction)didTapJoinButton:(UIButton *)button {
    button.selected = !button.selected;
    
    PFRelation *myGamesRelation = [[PFUser currentUser] relationforKey:@"games"];
    
    // Add the game to my games
    [myGamesRelation addObject:self.game];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Joining game", nil)];
    
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to join game", nil)];
            return;
        }
        
        PFRelation *gamePlayersRelation = [self.game relationforKey:@"players"];
        
        // Add me to the game's players
        [gamePlayersRelation addObject:[PFUser currentUser]];
        
        [self.game saveEventually:^(BOOL succeeded, NSError *error) {
            if (error) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to join game", nil)];
                return;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GCGameAddedNotification object:nil];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Successfully joined game", nil)];
            
            // Post to Facebook feed
            if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"joined a %@ game at %@ at %@, using GameCall Social Sports (http://www.gamecall.me/download)", nil), self.game[@"sport"], [self.dateFormatter stringFromDate:self.game[@"date"]], self.game[@"venue"][@"name"]];
                NSDictionary *parameters = @{
                    @"message": message,
                    @"link": @"http://www.gamecall.me/download",
                    @"picture": @"http://www.gamecall.me/img/logo-social.png",
                    @"name": NSLocalizedString(@"GameCall Social Sports", nil),
                    @"caption": NSLocalizedString(@"Notify friends with your game plans, and keep up with theirs.", nil),
                    @"description": NSLocalizedString(@"Login with your Facebook or Twitter account to make a GameCall and your friends will be notified via push notifications.\n Detail features:\n[Friends]\n -Sign up with Facebook, Twitter or Email.\n-Invite friends through Facebook, Twitter, email or SMS.\n[Favorite venues]\n-Easily search sports/fitness venues nearby & add as favorites.\n-Drop a pin to mark harder venues to find.\n[Call up friends for a game or join one of theirs]\n-Make a GameCall and notify your friends in just a few taps.\n-Notify your friends of your games and get see their response.\n-Find your friends' game and join the ones you like.", nil),
                };
                
                [PF_FBRequestConnection startWithGraphPath:@"me/feed" parameters:parameters HTTPMethod:@"POST" completionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
                    if (!result) {
                        TFLog(@"%@", error);
                        return;
                    }
                }];
            }
            
            // Tweet
            if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                NSString *status = [NSString stringWithFormat:NSLocalizedString(@"joined a %@ game at %@ at %@, using GameCall Social Sports (http://www.gamecall.me/download)", nil), self.game[@"sport"], [self.dateFormatter stringFromDate:self.game[@"date"]], self.game[@"venue"][@"name"]];
                
                NSDictionary *parameters = @{
                    @"status": status,
                    @"trim_user": @"true",
                    @"include_entities": @"false"
                };
                
                [[GCTwitterAPIClient sharedClient] updateStatusWithParameters:parameters block:^(NSDictionary *status, NSError *error) {
                    if (!status) {
                        TFLog(@"%@", error);
                        return;
                    }
                }];
            }
            
            // Send push notification to Game's Caller
            PFUser *caller = [self.game objectForKey:@"parent"];
            
            if (caller == [PFUser currentUser]) {
                return;
            }
            
            PFQuery *gamePlayersQuery = gamePlayersRelation.query;
            
            gamePlayersQuery.className = @"_User";
            
            [gamePlayersQuery findObjectsInBackgroundWithBlock:^(NSArray *players, NSError *error) {
                if (!players) {
                    TFLog(@"%@", error);
                    return;
                }
                
                if (players.count < 1) {
                    return;
                }
                
                NSMutableArray *playersObjectIds = [NSMutableArray new];
                
                for (PFUser *player in players) {
                    if ([player.objectId isEqualToString:caller.objectId]) {
                        PFPush *push = [[PFPush alloc] init];
                        NSString *hisOrHerChannel = [NSString stringWithFormat:@"GC%@", caller.objectId];
                        
                        [push setData:@{ @"alert" : @"A player has joined one of your games", @"alert" : @"default", @"name": @"GCPlayerJoinedNotification" }];
                        [push setChannel:hisOrHerChannel];
                        [push setPushToAndroid:NO];
                        [push expireAtDate:self.game[@"date"]];
                        [push sendPushInBackground];
                    }
                    
                    [playersObjectIds addObject:player.objectId];
                }
                
                // Send friends push notifications
                PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
                PFQuery *myFriendsQuery = myFriendsRelation.query;
                
                myFriendsQuery.className = @"_User";
                
                PFPush *push = [[PFPush alloc] init];
                
                [push setData:@{ @"alert" : @"A new game is available for you to join", @"sound" : @"default", @"name": @"GCGameAddedNotification" }];
                [push setQuery:myFriendsQuery];
                [push setPushToAndroid:NO];
                [push expireAtDate:self.game[@"date"]];
                [push sendPushInBackground];
            }];
        }];
    }];
}

- (IBAction)didTapQuitButton:(UIButton *)button {
    PFRelation *myGamesRelation = [[PFUser currentUser] relationforKey:@"games"];
    
    // Remove the game from my games
    [myGamesRelation removeObject:self.game];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Quitting game", nil)];
    
    [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to quit game", nil)];
            return;
        }
        
        PFRelation *playersRelation = [self.game relationforKey:@"players"];
        
        // Remove me from the players relation
        [playersRelation removeObject:[PFUser currentUser]];
        
        [self.game saveEventually:^(BOOL succeeded, NSError *error) {
            if (error) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to quit game", nil)];
                return;
            }
            
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Successfully quit game", nil)];
            [[NSNotificationCenter defaultCenter] postNotificationName:GCGameRemovedNotification object:nil];
            
            // Send push notification to Game's Caller
            PFUser *caller = [self.game objectForKey:@"parent"];
            
            if (caller == [PFUser currentUser]) {
                return;
            }
            
            PFPush *push = [[PFPush alloc] init];
            NSString *hisOrHerChannel = [NSString stringWithFormat:@"GC%@", caller.objectId];

            [push setData:@{ @"alert" : @"A player has quit one of your games", @"sound" : @"default", @"name": @"GCPlayerQuitNotification" }];
            [push setChannel:hisOrHerChannel];
            [push setPushToAndroid:NO];
            [push expireAtDate:self.game[@"date"]];
            [push sendPushInBackground];
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

    self.joinButton.enabled = self.quitButton.enabled = isReachable;
    
    if (isReachable) {
        [self customizePlayersCell];
        [self customizeCallToActionButtons];
    }
}

- (void)customizeBackgroundImage {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

- (void)customizeFauxSections {
    for (UIView *fauxSection in self.fauxSections) {
        fauxSection.backgroundColor = [UIColor blackTranslucentColor];
        fauxSection.layer.borderWidth = 1.f;
        fauxSection.layer.borderColor = [UIColor offWhiteColor].CGColor;
        fauxSection.layer.cornerRadius = 10.f;
    }
}

- (void)customizeCallerCell {    
    PFObject *caller = [self.game objectForKey:@"parent"];
    PFFile *callerPhotoFile = [caller objectForKey:@"photo"];
    
    self.callerPhotoImageView.image = [UIImage imageNamed:@"photo-placeholder"];
    self.callerPhotoImageView.file = callerPhotoFile;
    
    [self.callerPhotoImageView loadInBackground];
    
    NSString *firstName = [[caller objectForKey:@"firstName"] capitalizedString];
    NSString *lastName = [[caller objectForKey:@"lastName"] capitalizedString];
    NSString *compositeName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    self.callerNameLabel.text = compositeName;
}

- (void)customizeSpaceTimeCell {
    NSString *sport = [self.game objectForKey:@"sport"];
    UIImage *sportIndicatorImage = [UIImage imageNamed:[NSString stringWithFormat:@"selector-%@-normal", sport]];
    
    self.sportIndicatorImageView.image = sportIndicatorImage;
    
    NSDate *date = [self.game objectForKey:@"date"];
    
    self.timeLabel.text = [self.dateFormatter stringFromDate:date];
    
    PFObject *venue = [self.game objectForKey:@"venue"];
    
    self.spaceLabel.text = [venue objectForKey:@"name"];
}

- (void)customizePlayersCell {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        PFRelation *playersRelation = [self.game relationforKey:@"players"];
        PFQuery *playersQuery = playersRelation.query;
        NSError *errorFindingPlayers;
        NSArray *players = [playersQuery findObjects:&errorFindingPlayers];
        
        if (!players) {
            TFLog(@"%@", errorFindingPlayers);
            return;
        }
        
        BOOL isPlayer = NO;
        
        for (PFUser *player in players) {
            if (![player.objectId isEqualToString:[PFUser currentUser].objectId]) {
                continue;
            }
            
            isPlayer = YES;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.playersGroupedFlipNumberView animateToValue:players.count withDuration:1.0];
            self.joinButton.hidden = isPlayer;
            self.quitButton.hidden = !isPlayer;
        });
    });
}

- (void)customizeMapView {
    PFObject *venue = [self.game objectForKey:@"venue"];
    PFGeoPoint *location = [venue objectForKey:@"location"];
    CLLocationCoordinate2D coordinate = {location.latitude, location.longitude};
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, kGCGameDetailsMapViewRadius, kGCGameDetailsMapViewRadius);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];

    annotation.coordinate = coordinate;
    [self.mapView addAnnotation:annotation];
    [self.mapView setRegion:adjustedRegion];
    
    self.mapView.layer.cornerRadius = 10.f;
}

- (void)customizeCallToActionButtons {
    self.callToActionButtons = [self.callToActionButtons sortedArrayUsingComparator:^NSComparisonResult(UIButton *button, UIButton *otherButton) {
        return button.tag > otherButton.tag;
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue.identifier isEqualToString:GCDisclosePlayerDetailsSegueIdentifier]) {
        return;
    }
    
    [(GCPlayersViewController *)segue.destinationViewController setGame:self.game];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeBackgroundImage];
    [self customizeFauxSections];
    [self customizeCallerCell];
    [self customizeSpaceTimeCell];
    [self customizeMapView];
    [self customizeCallToActionButtons];
    [self customizePlayersCell];
    
    [self.playersCell addSubview:self.playersGroupedFlipNumberView];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customizePlayersCell) name:GCGameAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customizePlayersCell) name:GCGameRemovedNotification object:nil];
}

- (void)viewDidUnload {
    [self setGame:nil];
    [self setFauxSections:nil];
    [self setCallerCell:nil];
    [self setCallerPhotoImageView:nil];
    [self setCallerNameLabel:nil];
    [self setSpaceTimeCell:nil];
    [self setSportIndicatorImageView:nil];
    [self setDateFormatter:nil];
    [self setTimeLabel:nil];
    [self setSpaceLabel:nil];
    [self setPlayersCell:nil];
    [self setPlayersGroupedFlipNumberView:nil];
    [self setMapView:nil];
    [self setCallToActionButtons:nil];
    [self setJoinButton:nil];
    [self setQuitButton:nil];
    
    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.playersGroupedFlipNumberView.frame = CGRectMake(15.f, 10.f, 64.f, 64.f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCGameAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GCGameRemovedNotification object:nil];
}

@end
