//
//  GCSettingsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-06.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCSettingsViewController.h"
#import "UIColor+GCColors.h"
#import "GCPlainTableViewSectionHeaderView.h"

@interface GCSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *facebookCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *twitterCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *supportCell;

- (IBAction)linkCurrentUserWithFacebook:(UIButton *)button;
- (IBAction)linkCurrentUserWithTwitter:(UIButton *)button;
- (IBAction)sendEmailToSupport;

- (void)customizeTabBarItem;
- (void)customizeTableView;
- (void)customizeLinkButtons;

@end

@implementation GCSettingsViewController

#pragma mark - GCSettingsViewController

- (IBAction)linkCurrentUserWithFacebook:(UIButton *)button {    
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }
    
    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:@[ @"email", @"publish_actions" ] block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to link this account with Facebook", nil)];
            return;
        }
        
        UIImage *normalBackgroundImage = [UIImage imageNamed:@"button-add-friend-normal"];
        UIImage *highlightedBackgroundImage = [UIImage imageNamed:@"button-add-friend-highlighted"];
     
        [button setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.text = NSLocalizedString(@"Connected", nil);
        button.contentEdgeInsets = UIEdgeInsetsMake(2.f, 10.f, 0.f, 0.f);
        button.userInteractionEnabled = NO;
    }];
}

- (IBAction)linkCurrentUserWithTwitter:(UIButton *)button {
    if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }
    
    [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to link this account with Twitter", nil)];
            return;
        }
        
        UIImage *normalBackgroundImage = [UIImage imageNamed:@"button-add-friend-normal"];
        UIImage *highlightedBackgroundImage = [UIImage imageNamed:@"button-add-friend-highlighted"];
        
        [button setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:highlightedBackgroundImage forState:UIControlStateHighlighted];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.text = NSLocalizedString(@"Connected", nil);
        button.userInteractionEnabled = NO;
    }];
}

- (IBAction)sendEmailToSupport {
    if (![MFMailComposeViewController canSendMail]) {
        return;
    }
    
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    NSString *firstName = [[PFUser currentUser] objectForKey:@"firstName"];
    NSString *lastName = [[PFUser currentUser] objectForKey:@"lastName"];
    
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setToRecipients:@[ @"support@gamecall.me" ]];
    [mailComposeViewController setSubject:[NSString stringWithFormat:@"Support request from %@ %@", firstName.capitalizedString, lastName.capitalizedString]];
    
    [self presentModalViewController:mailComposeViewController animated:YES];
}

- (void)customizeTabBarItem {
    UIImage *selectedImage = [UIImage imageNamed:@"settings-selected"];
    UIImage *unselectedImage = [UIImage imageNamed:@"settings-normal"];
    
    self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:0];
    [self.navigationController.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
    [self.navigationController.tabBarItem setImageInsets:UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f)];
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

- (void)customizeLinkButtons {
    NSString *facebookNormalBackgroundImageName, *facebookHighlightedBackgroundImageName, *facebookTitle;
    UIButton *facebookButton = (UIButton *)[self.facebookCell viewWithTag:100];
    BOOL isFacebookButtonEnabled = ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    
    facebookNormalBackgroundImageName = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] ? @"button-add-friend-normal" : @"button-invite-normal";
    facebookHighlightedBackgroundImageName = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] ? @"button-add-friend-highlighted" : @"button-invite-highlighted";
    facebookTitle = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] ? NSLocalizedString(@"Connected", nil) : NSLocalizedString(@"Connect", nil);
    
    UIImage *facebookNormalBackgroundImage = [UIImage imageNamed:facebookNormalBackgroundImageName];
    UIImage *facebookHighlightedBackgroundImage = [UIImage imageNamed:facebookHighlightedBackgroundImageName];
    
    [facebookButton setBackgroundImage:facebookNormalBackgroundImage forState:UIControlStateNormal];
    [facebookButton setBackgroundImage:facebookHighlightedBackgroundImage forState:UIControlStateHighlighted];
    facebookButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    facebookButton.titleLabel.text = facebookTitle;
    facebookButton.userInteractionEnabled = isFacebookButtonEnabled;
    
    NSString *twitterNormalBackgroundImageName, *twitterHighlightedBackgroundImageName, *twitterTitle;
    UIButton *twitterButton = (UIButton *)[self.twitterCell viewWithTag:100];
    BOOL isTwitterButtonEnabled = ![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
    
    twitterNormalBackgroundImageName = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]] ? @"button-add-friend-normal" : @"button-invite-normal";
    twitterHighlightedBackgroundImageName = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]] ? @"button-add-friend-highlighted" : @"button-invite-highlighted";
    twitterTitle = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]] ? NSLocalizedString(@"Connected", nil) : NSLocalizedString(@"Connect", nil);
    
    UIImage *twitterNormalBackgroundImage = [UIImage imageNamed:twitterNormalBackgroundImageName];
    UIImage *twitterHighlightedBackgroundImage = [UIImage imageNamed:twitterHighlightedBackgroundImageName];
    
    [twitterButton setBackgroundImage:twitterNormalBackgroundImage forState:UIControlStateNormal];
    [twitterButton setBackgroundImage:twitterHighlightedBackgroundImage forState:UIControlStateHighlighted];
    twitterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    twitterButton.titleLabel.text = twitterTitle;
    twitterButton.userInteractionEnabled = isTwitterButtonEnabled;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case GCSettingsTableViewSectionGeneral:
            return NSLocalizedString(@"General", nil);
            
        case GCSettingsTableViewSectionSocial:
            return NSLocalizedString(@"Social", nil);
            
        case GCSettingsTableViewSectionAbout:
            return NSLocalizedString(@"About", nil);
            
        case GCSettingsTableViewSectionLegal:
            return NSLocalizedString(@"Legal", nil);
            
        default:
            return nil;
    }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.frame.size.width, cell.frame.size.height)];
    
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.supportCell) {
        [self sendEmailToSupport];
        return;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    [self customizeLinkButtons];
}

- (void)viewDidUnload {
    [self setFacebookCell:nil];
    [self setTwitterCell:nil];
    [self setSupportCell:nil];
    
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

@end
