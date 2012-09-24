//
//  GCGameCallViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-06.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGameCallViewController.h"
#import "UIColor+GCColors.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "PFUser+GCUser.h"
#import "GCTwitterAPIClient.h"
#import "PSAlertView.h"

@interface GCGameCallViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSArray *favorites;
@property (strong, nonatomic) NSArray *sports;
@property (strong, nonatomic) PFObject *where;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDate *when;
@property (copy, nonatomic) NSString *sport;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *sportsRadioButtons;
@property (strong, nonatomic) UIButton *selectedSportRadioButton;

@property (weak, nonatomic) IBOutlet UITableViewCell *whereCell;
@property (weak, nonatomic) IBOutlet UITextField *whereTextField;
@property (strong, nonatomic) IBOutlet UIPickerView *wherePickerView;

@property (weak, nonatomic) IBOutlet UITableViewCell *whenCell;
@property (weak, nonatomic) IBOutlet UITextField *whenTextField;
@property (strong, nonatomic) IBOutlet UIDatePicker *whenPickerView;

@property (strong, nonatomic) IBOutlet UIToolbar *inputAccessoryToolBarView;

@property (weak, nonatomic) IBOutlet UIButton *goButton;

- (IBAction)didTapCancelButton:(UIButton *)button;
- (IBAction)willEnableGoButton;
- (IBAction)didTapDoneButton:(UIButton *)button;
- (IBAction)didTapSportRadioButton:(UIButton *)button;
- (IBAction)didTapGoButton:(UIButton *)button;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeLeftBarButtonItem;
- (void)customizeTableView;
- (void)customizeWhereTextField;
- (void)customizeWherePickerView;
- (void)customizeWhenTextField;
- (void)customizeSportsRadioButtons;

@end

@implementation GCGameCallViewController

#pragma mark - GCGameCallViewController

- (NSArray *)sports {
    if (!_sports) {
        _sports = [[NSUserDefaults standardUserDefaults] arrayForKey:@"sports"];
    }
    
    return _sports;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    return _dateFormatter;
}

- (UIPickerView *)wherePickerView {
    if (!_wherePickerView) {
        _wherePickerView = [[UIPickerView alloc] init];
        _wherePickerView.dataSource = self;
        _wherePickerView.delegate = self;
        _wherePickerView.showsSelectionIndicator = YES;
    }
    
    return _wherePickerView;
}

- (UIDatePicker *)whenPickerView {
    if (!_whenPickerView) {
        NSDate *date = [NSDate date];
        NSInteger minimumInterval = 10;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
        NSUInteger remainder = (components.minute % minimumInterval);
        
        if (remainder > 0) {
            date = [date dateByAddingTimeInterval:60 * (minimumInterval - remainder)];
        }
        
        _whenPickerView = [[UIDatePicker alloc] init];
        _whenPickerView.minuteInterval = minimumInterval;
        _whenPickerView.minimumDate = date;
    }
    
    return _whenPickerView;
}

- (UIToolbar *)inputAccessoryToolBarView {
    if (!_inputAccessoryToolBarView) {
        _inputAccessoryToolBarView = [[UIToolbar alloc] init];
        _inputAccessoryToolBarView.barStyle = UIBarStyleDefault;
        [_inputAccessoryToolBarView sizeToFit];
        
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton:)];
        
        UIBarButtonItem *flexibleSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDoneButton:)];
        
        _inputAccessoryToolBarView.items = @[ cancelBarButtonItem, flexibleSpaceBarButtonItem, doneBarButtonItem ];
    }
    
    return _inputAccessoryToolBarView;
}

- (IBAction)didTapCancelButton:(UIBarButtonItem *)button {
    [self.view endEditing:YES];
    
    [(UIImageView *)self.whereCell.accessoryView setHighlighted:NO];
    [(UIImageView *)self.whenCell.accessoryView setHighlighted:NO];
}

- (IBAction)willEnableGoButton {
    NSArray *selectedSports = [self.sportsRadioButtons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected == YES"]];
    
    self.goButton.enabled = self.whereTextField.text.length > 0 && self.whenTextField.text.length > 0 && selectedSports.count > 0;
}

- (IBAction)didTapDoneButton:(UIButton *)button {
    UIImageView *accessoryView;
    UITextField *textField;
    NSString *text;
    
    if (self.whereTextField.isFirstResponder) {
        if (self.favorites.count < 1) {
            return;
        }
        
        NSInteger row = [self.wherePickerView selectedRowInComponent:0];
        PFObject *favorite = [self.favorites objectAtIndex:row];
        
        accessoryView = (UIImageView *)self.whereCell.accessoryView;
        textField = self.whereTextField;
        text = [favorite objectForKey:@"name"];
        
        self.where = favorite;
    } else {
        NSDate *date = self.whenPickerView.date;
        
        accessoryView = (UIImageView *)self.whenCell.accessoryView;
        textField = self.whenTextField;
        text = [self.dateFormatter stringFromDate:date];
        self.when = date;
    }
    
    accessoryView.highlighted = NO;
    textField.text = text;
    [textField resignFirstResponder];
}

- (IBAction)didTapSportRadioButton:(UIButton *)button {
    if (button == self.selectedSportRadioButton) {
        return;
    }
    
    NSInteger index = [self.sportsRadioButtons indexOfObject:button];
    NSString *sport = [self.sports objectAtIndex:index];
    
    self.selectedSportRadioButton.selected = NO;
    self.selectedSportRadioButton = button;
    self.selectedSportRadioButton.selected= YES;
    
    self.sport = sport;
    [self willEnableGoButton];
}

- (IBAction)didTapGoButton:(UIBarButtonItem *)button {
    // Create game
    PFObject *game = [PFObject objectWithClassName:@"Game"];
    
    [game setObject:[PFUser currentUser] forKey:@"parent"];
    [game setObject:self.where forKey:@"venue"];
    [game setObject:self.when forKey:@"date"];
    [game setObject:self.sport forKey:@"sport"];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving game...", nil)];
    
    [game saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to save game", nil)];
            return;
        }
        
        // Add to my games
        PFRelation *myGamesRelation = [[PFUser currentUser] relationforKey:@"games"];
        
        [myGamesRelation addObject:game];
        [SVProgressHUD setStatus:NSLocalizedString(@"Adding to my games...", nil)];
        
        [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add game", nil)];
                return;
            }
            
            // Add me as a player
            PFRelation *gamePlayersRelation = [game relationforKey:@"players"];
            
            [gamePlayersRelation addObject:[PFUser currentUser]];
            [SVProgressHUD setStatus:NSLocalizedString(@"Adding as a player...", nil)];
            
            [game saveEventually:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to add as a player", nil)];
                    return;
                }
                
                [SVProgressHUD dismiss];
                [[NSNotificationCenter defaultCenter] postNotificationName:GCGameAddedNotification object:nil];
                [self dismissModalViewControllerAnimated:YES];
            }];
            
            // Post to Facebook feed
            if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"called a %@ game at %@ at %@, using GameCall Social Sports (http://www.gamecall.me/download)", nil), self.sport, [self.dateFormatter stringFromDate:self.when], self.where[@"name"]];
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
                NSString *status = [NSString stringWithFormat:NSLocalizedString(@"called a %@ game at %@ at %@, using GameCall Social Sports (http://www.gamecall.me/download)", nil), self.sport, [self.dateFormatter stringFromDate:self.when], self.where[@"name"]];
                
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
            
            // Send friends push notifications
            PFRelation *myFriendsRelation = [[PFUser currentUser] relationforKey:@"friends"];
            PFQuery *myFriendsQuery = myFriendsRelation.query;
            
            myFriendsQuery.className = @"_User";
            
            [myFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *friends, NSError *error) {
                if (!friends) {
                    TFLog(@"%@", error);
                    return;
                }
                
                for (PFUser *friend in friends) {
                    NSString *hisOrHerChannel = [NSString stringWithFormat:@"GC%@", friend.objectId];
                    PFPush *push = [[PFPush alloc] init];
                    
                    [push setData:@{ @"alert" : @"A new game is available for you to join", @"sound" : @"default", @"name": @"GCGameAddedNotification" }];
                    [push setChannel:hisOrHerChannel];
                    [push setPushToAndroid:NO];
                    [push expireAtDate:game[@"date"]];
                    [push sendPushInBackground];
                }
            }];
            
            // Add as game at this venue
            PFObject *venue = [game objectForKey:@"venue"];
            PFRelation *venueGamesRelation = [venue relationforKey:@"games"];
            
            [venueGamesRelation addObject:game];
            [venue saveEventually];
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
    
    for (UIButton *sportsRadioButton in self.sportsRadioButtons) {
        sportsRadioButton.enabled = isReachable;
    }
    
    self.whereCell.backgroundColor = self.whenCell.backgroundColor = isReachable ? [UIColor colorWithWhite:0.f alpha:0.3f] : [UIColor colorWithWhite:0.f alpha:0.15f];
    
    self.whereTextField.enabled = self.whenTextField.enabled = isReachable;
    
    if (!isReachable) {
        self.goButton.enabled = isReachable;
        return;
    }
    
    [self willEnableGoButton];
}

- (void)customizeLeftBarButtonItem {
    self.navigationItem.leftBarButtonItem.target = self;
    self.navigationItem.leftBarButtonItem.action = @selector(dismissModalViewControllerAnimated:);
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.tableView.separatorColor = [UIColor offWhiteColor];
}

- (void)customizeWhereTextField {
    self.whereTextField.inputView = self.wherePickerView;
    self.whereTextField.inputAccessoryView = self.inputAccessoryToolBarView;
}

- (void)customizeWherePickerView {
    [[PFUser currentUser] findFavoritesInBackgroundWithBlock:^(NSArray *favorites, NSError *error) {
        if (!favorites) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve favorites", nil)];
            return;
        }
        
        self.favorites = favorites;
        [self.wherePickerView reloadComponent:0];
    }];
}

- (void)customizeWhenTextField {
    self.whenTextField.inputView = self.whenPickerView;
    self.whenTextField.inputAccessoryView = self.inputAccessoryToolBarView;
}

- (void)customizeSportsRadioButtons {    
    [self.sports enumerateObjectsUsingBlock:^(NSString *sport, NSUInteger idx, BOOL *stop) {
        NSString *normalBackgroundImageName = [NSString stringWithFormat:@"selector-%@-normal", sport];
        NSString *selectedBackgroundImageName = [NSString stringWithFormat:@"selector-%@-selected", sport];
        UIImage *normalBackgroundImage = [UIImage imageNamed:normalBackgroundImageName];
        UIImage *selectedBackgroundImage = [UIImage imageNamed:selectedBackgroundImageName];
        UIButton *button = [self.sportsRadioButtons objectAtIndex:idx];
        
        [button setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
        button.enabled = YES;
    }];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.favorites.count > 0 ? self.favorites.count : 1;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {    
    if (self.favorites.count < 1) {
        return NSLocalizedString(@"No favorited venues found", nil);
    }
    
    PFObject *favorite = [self.favorites objectAtIndex:row];
    
    return [favorite objectForKey:@"name"];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 5.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == tableView.numberOfSections - 1) {
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        return;
    }
    
    cell.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.3f];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.whereCell) {
        [(UIImageView *)self.whereCell.accessoryView setHighlighted:YES];
        [self.whereTextField becomeFirstResponder];
        
        return;
    }
    
    if (cell == self.whenCell) {
        [(UIImageView *)self.whenCell.accessoryView setHighlighted:YES];
        [self.whenTextField becomeFirstResponder];
        return;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeLeftBarButtonItem];
    [self customizeTableView];
    [self customizeWhereTextField];
    [self customizeWherePickerView];
    [self customizeWhenTextField];
    [self customizeSportsRadioButtons];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setFavorites:nil];
    [self setSports:nil];
    [self setWhere:nil];
    [self setDateFormatter:nil];
    [self setWhen:nil];
    [self setSportsRadioButtons:nil];
    [self setSelectedSportRadioButton:nil];
    [self setWhereCell:nil];
    [self setWhereTextField:nil];
    [self setWherePickerView:nil];
    [self setWhenCell:nil];
    [self setWhenTextField:nil];
    [self setWhenPickerView:nil];
    [self setInputAccessoryToolBarView:nil];
    [self setGoButton:nil];
    
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
