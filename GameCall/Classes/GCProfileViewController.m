//
//  GCProfileViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-22.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCProfileViewController.h"
#import "PSActionSheet.h"
#import "AFImageRequestOperation.h"
#import "UIColor+GCColors.h"
#import "GCImageView.h"
#import "AppDelegate.h"
#import "PFUser+GCAdditions.h"

static NSString * const kGCSignedUpSegueIdentifer = @"GCSignedUpSegue";

@interface GCProfileViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *fauxSection;
@property (weak, nonatomic) IBOutlet GCImageView *photoView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextField;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *genderButtons;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *sportsIndicatorButtons;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;

- (IBAction)didTapPhotoButton:(UIButton *)button;
- (IBAction)didTapFemaleGenderButton:(UIButton *)button;
- (IBAction)didTapMaleGenderButton:(UIButton *)button;
- (IBAction)didTapLogOutButton;
- (IBAction)willEnableDoneButton;
- (IBAction)validateProfile;

- (void)didTapCancelButton:(UIBarButtonItem *)button;
- (void)didTapNextButton:(UIBarButtonItem *)button;
- (void)didChangeBirthday:(UIDatePicker *)picker;
- (void)didTapGenderButton:(UIButton *)button;
- (void)autoFillPhoto;
- (void)autoFillFirstName;
- (void)autoFillLastName;
- (void)autoFillEmail;
- (void)autoFillBirthday;
- (void)autoFillGender;
- (void)autoFillSports;
- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeNavigationItem;
- (void)customizeTableView;
- (void)customizeInputView;

@end

@implementation GCProfileViewController

#pragma mark - GCProfileViewController

- (NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateStyle = NSDateFormatterMediumStyle;
        _formatter.timeStyle = NSDateFormatterNoStyle;
    }
    
    return _formatter;
}

- (IBAction)didTapPhotoButton:(UIButton *)button {
    PSActionSheet *sheet = [PSActionSheet sheetWithTitle:nil];
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Take Photo", nil) block:^{
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Choose Photo", nil) block:^{
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
    }
    
    [sheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
    
    [sheet showInView:self.view];
}

- (IBAction)didTapFemaleGenderButton:(UIButton *)button {
    [self didTapGenderButton:button];
}

- (IBAction)didTapMaleGenderButton:(UIButton *)button {
    [self didTapGenderButton:button];
}

- (IBAction)didTapLogOutButton {
    [[PFUser currentUser] logOutFromGameCall];
}

- (IBAction)willEnableDoneButton {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    BOOL isReachable = appDelegate.reachability.currentReachabilityStatus != NotReachable;
    
    self.doneButton.enabled = self.firstNameTextField.text && self.firstNameTextField.text.length && self.lastNameTextField.text && self.lastNameTextField.text.length && self.emailTextField.text && self.emailTextField.text.length && [[NSUserDefaults standardUserDefaults] arrayForKey:@"sports"].count > 0 && isReachable;
}

- (IBAction)validateProfile {
    [[PFUser currentUser] setObject:self.firstNameTextField.text.lowercaseString forKey:@"firstName"];
    [[PFUser currentUser] setObject:self.lastNameTextField.text.lowercaseString forKey:@"lastName"];
    [PFUser currentUser].username = [PFUser currentUser].email = self.emailTextField.text;
    
    NSDate *birthday = [self.formatter dateFromString:self.birthdayTextField.text];
    
    if (birthday) {
        [[PFUser currentUser] setObject:birthday forKey:@"birthday"];
    } else {
        [[PFUser currentUser] setObject:[NSNull null] forKey:@"birthday"];
    }
    
    UIButton *femaleGenderButton = [self.genderButtons objectAtIndex:0];
    UIButton *maleGenderButton = [self.genderButtons lastObject];
    
    if (femaleGenderButton.selected) {
        [[PFUser currentUser] setObject:@"female" forKey:@"gender"];
    } else if (maleGenderButton.selected) {
        [[PFUser currentUser] setObject:@"male" forKey:@"gender"];
    } else {
        [[PFUser currentUser] setObject:[NSNull null] forKey:@"gender"];
    }
    
    NSString *myChannel = [NSString stringWithFormat:@"GC%@", [PFUser currentUser].objectId];
    
    [PFPush subscribeToChannelInBackground:myChannel block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            TFLog(@"%@", error);
        }
    }];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving profile...", nil)];
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to save profile", nil)];
            return;
        }
        
        [SVProgressHUD dismiss];
        [self performSegueWithIdentifier:kGCSignedUpSegueIdentifer sender:self];
    }];
}

- (void)didTapCancelButton:(UIBarButtonItem *)button {
    [self.view endEditing:YES];
}

- (void)didTapNextButton:(UIBarButtonItem *)button {
    [self.textFields enumerateObjectsUsingBlock:^(UITextField *textField, NSUInteger idx, BOOL *stop) {
        if (textField.isFirstResponder) {
            if (textField == self.birthdayTextField) {
                NSDate *birthday = [(UIDatePicker *)self.birthdayTextField.inputView date];
                
                self.birthdayTextField.text = [self.formatter stringFromDate:birthday];
            }
            
            NSUInteger nextIndex = idx + 1;
            
            if (nextIndex == self.textFields.count) {
                [self.view endEditing:YES];
                *stop = YES;
                
                return;
            }
            
            UITextField *nextResponder = [self.textFields objectAtIndex:nextIndex];
            [nextResponder becomeFirstResponder];
            *stop = YES;
        }
    }];
}

- (void)didChangeBirthday:(UIDatePicker *)picker {
    self.birthdayTextField.text = [self.formatter stringFromDate:picker.date];
}

- (void)didTapGenderButton:(UIButton *)button {
    button.selected = !button.selected;
    
    NSUInteger index = [self.genderButtons indexOfObject:button];
    NSUInteger otherIndex = index ^ 1;
    
    [[self.genderButtons objectAtIndex:otherIndex] setSelected:NO];
}

- (void)autoFillPhoto {
    __block PFFile *photoFile = [[PFUser currentUser] objectForKey:@"photo"];
    UIImage *placeholderImage = [UIImage imageNamed:@"photo-placeholder"];
    
    self.photoView.image = placeholderImage;
    
    if (photoFile) {
        self.photoView.file = photoFile;
        [self.photoView loadInBackground];
        
        return;
    }
    
    if (!self.photoURLString) {
        return;
    }
    
    NSURLRequest *photoRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.photoURLString]];
    
    [[AFImageRequestOperation imageRequestOperationWithRequest:photoRequest success:^(UIImage *image) {
        NSData *photoData = UIImagePNGRepresentation(image);
        photoFile = [PFFile fileWithData:photoData];
        
        [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                TFLog(@"%@", error);
                return;
            }
            
            [[PFUser currentUser] setObject:photoFile forKey:@"photo"];
            [[PFUser currentUser] saveEventually:^(BOOL succeeded, NSError *error) {
                if (error) {
                    TFLog(@"%@", error);
                    return;
                }
                
                self.photoView.file = photoFile;
                
                [self.addPhotoButton.titleLabel removeFromSuperview];
                [self.photoView loadInBackground];
            }];
        }];
    }] start];
}

- (void)autoFillFirstName {
    NSString *firstName = [[PFUser currentUser] objectForKey:@"firstName"];
    
    if (firstName) {
        self.firstNameTextField.text = firstName.capitalizedString;
    }
}

- (void)autoFillLastName {
    NSString *lastName = [[PFUser currentUser] objectForKey:@"lastName"];
    
    if (lastName) {
        self.lastNameTextField.text = lastName.capitalizedString;
    }
}

- (void)autoFillEmail {
    NSString *email = [[PFUser currentUser] objectForKey:@"email"];
    
    if (email) {
        self.emailTextField.text = email;
    }
}

- (void)autoFillBirthday {
    NSDate *birthday = [[PFUser currentUser] objectForKey:@"birthday"];
    
    if (birthday) {
        self.birthdayTextField.text = [self.formatter stringFromDate:birthday];
    }
}

- (void)autoFillGender {
    NSString *gender = [[PFUser currentUser] objectForKey:@"gender"];
    
    if (gender == (id)[NSNull null] || ![gender isKindOfClass:[NSString class]]) {
        gender = nil;
    }
    
    if (gender) {
        UIButton *genderButton;
        
        if ([gender caseInsensitiveCompare:@"female"] == NSOrderedSame) {
            genderButton = [self.genderButtons objectAtIndex:0];
        } else {
            genderButton = [self.genderButtons objectAtIndex:1];
        }
        
        genderButton.selected = YES;
    }
}

- (void)autoFillSports {
    NSArray *sports = [[NSUserDefaults standardUserDefaults] arrayForKey:@"sports"];
    
    if (!sports) {
        sports = [PFUser currentUser][@"me"];
    }
    
    self.sportsIndicatorButtons = [self.sportsIndicatorButtons sortedArrayUsingComparator:^NSComparisonResult(UIButton *button, UIButton *otherButton) {
        return button.tag > otherButton.tag;
    }];
    
    [self.sportsIndicatorButtons enumerateObjectsUsingBlock:^(UIButton *sportIndicator, NSUInteger idx, BOOL *stop) {
        [sportIndicator setBackgroundImage:[UIImage imageNamed:@"sports-indicator-placeholder"] forState:UIControlStateNormal];
    }];
    
    [sports enumerateObjectsUsingBlock:^(NSString *sport, NSUInteger idx, BOOL *stop) {
        NSString *imageName = [NSString stringWithFormat:@"selector-%@-normal", sport];
        UIImage *backgroundImage = [UIImage imageNamed:imageName];
        UIButton *sportIndicator = [self.sportsIndicatorButtons objectAtIndex:idx];
        
        [sportIndicator setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.addPhotoButton.enabled = isReachable;
    
    for (UIButton *sportsIndicatorButton in self.sportsIndicatorButtons) {
        sportsIndicatorButton.enabled = isReachable;
    }
    
    [self willEnableDoneButton];
}

- (void)customizeNavigationItem {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.delegate = self;
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.tableView.separatorColor = [UIColor offWhiteColor];
    
    self.fauxSection.backgroundColor = [UIColor blackTranslucentColor];
    self.fauxSection.layer.borderWidth = 1.f;
    self.fauxSection.layer.borderColor = [UIColor offWhiteColor].CGColor;
    self.fauxSection.layer.cornerRadius = 10.f;
    
    self.textFields = [self.textFields sortedArrayUsingComparator:^NSComparisonResult(UITextField *textField, UITextField *otherTextField) {
        return textField.tag > otherTextField.tag;
    }];
    
    self.genderButtons = [self.genderButtons sortedArrayUsingComparator:^NSComparisonResult(UIButton *button, UIButton *otherButton) {
        return button.tag > otherButton.tag;
    }];
}

- (void)customizeInputView {
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton:)];
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *nextButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(didTapNextButton:)];
    
    toolbar.items = @[ cancelButtonItem, flexibleSpaceButtonItem, nextButtonItem ];
    
    [toolbar sizeToFit];
    
    for (UITextField *textField in self.textFields) {
        textField.inputAccessoryView = toolbar;
    }
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.maximumDate = [NSDate date];
    
    self.birthdayTextField.inputView = datePicker;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *photo = [info objectForKey:UIImagePickerControllerEditedImage];
        
    self.photoView.image = photo;
    [self.addPhotoButton.titleLabel removeFromSuperview];
    [self dismissModalViewControllerAnimated:YES];
    
    NSData *photoData = UIImagePNGRepresentation(photo);
    PFFile *photoFile = [PFFile fileWithData:photoData];
    
    [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            TFLog(@"%@", error);
            return;
        }
        
        [[PFUser currentUser] setObject:photoFile forKey:@"photo"];
        [[PFUser currentUser] saveEventually];
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

#pragma mark - UITableViewDelegate

#define kGCProfileTableViewOptionalSection 2

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != kGCProfileTableViewOptionalSection) {
        return nil;
    }
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 0.f, 0.f, 0.f)];
    
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    headerLabel.textColor = [UIColor offBlackColor];
    headerLabel.shadowColor = [UIColor colorWithWhite:1.f alpha:0.7f];
    headerLabel.shadowOffset = CGSizeMake(0.f, 1.f);
    headerLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    headerLabel.text = NSLocalizedString(@"Optional", nil);
    [headerLabel sizeToFit];
    
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        return;;
    }
    
    cell.backgroundColor = [UIColor blackTranslucentColor];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    [self customizeInputView];
    [self autoFillPhoto];
    [self autoFillFirstName];
    [self autoFillLastName];
    [self autoFillEmail];
    [self autoFillBirthday];
    [self autoFillGender];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {    
    [self setFauxSection:nil];
    [self setPhotoView:nil];
    [self setAddPhotoButton:nil];
    [self setTextFields:nil];
    [self setFirstNameTextField:nil];
    [self setLastNameTextField:nil];
    [self setEmailTextField:nil];
    [self setBirthdayTextField:nil];
    [self setFormatter:nil];
    [self setGenderButtons:nil];
    [self setSportsIndicatorButtons:nil];
    [self setDoneButton:nil];
    [self setLogOutButton:nil];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self customizeNavigationItem];
    [self autoFillSports];
    [self willEnableDoneButton];
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
