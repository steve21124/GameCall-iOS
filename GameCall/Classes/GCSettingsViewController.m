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

@property (weak, nonatomic) IBOutlet UITableViewCell *supportCell;

- (IBAction)sendEmailToSupport;

- (void)customizeTabBarItem;
- (void)customizeTableView;

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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case GCSettingsTableViewSectionGeneral:
            return NSLocalizedString(@"General", nil);
            
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
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
}

- (void)viewDidUnload {
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
