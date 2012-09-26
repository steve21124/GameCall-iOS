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

- (IBAction)sendEmailToSupport;
- (IBAction)didTapSocialSwitch:(UISwitch *)theSwitch;

- (void)customizeTabBarItem;
- (void)customizeTableView;
- (void)customizeSocialSwitches;

@end

@implementation GCSettingsViewController

#pragma mark - GCSettingsViewController

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

- (IBAction)didTapSocialSwitch:(UISwitch *)theSwitch {    
    if (theSwitch.superview.superview == self.facebookCell) {
        if (theSwitch.on) {
            [PFFacebookUtils linkUser:[PFUser currentUser] permissions:@[ @"email", @"publish_actions" ] block:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to connect with Facebook", nil)];
                    theSwitch.on = !theSwitch.on;
                    return;
                }
            }];
        } else {
            [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to disconnect with Facebook", nil)];
                    theSwitch.on = !theSwitch.on;
                    return;
                }
            }];
        }
        
        return;
    }
    
    if (theSwitch.on) {
        [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to connect with Twitter", nil)];
                theSwitch.on = !theSwitch.on;
                return;
            }
        }];
    } else {
        [PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to disconnect with Twitter", nil)];
                theSwitch.on = !theSwitch.on;
                return;
            }
        }];
    }
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

- (void)customizeSocialSwitches {
    UISwitch *facebookSwitch = (UISwitch *)[self.facebookCell viewWithTag:100];
    UISwitch *twitterSwitch = (UISwitch *)[self.twitterCell viewWithTag:100];
    
    facebookSwitch.on = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
    twitterSwitch.on = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
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
    [self customizeSocialSwitches];
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
