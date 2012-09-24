//
//  GCLogInViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-12.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCLogInViewController.h"
#import "Parse/Parse.h"
#import "Constants.h"
#import "GCTwitterAPIClient.h"
#import "GCProfileViewController.h"
#import "PSAlertView.h"
#import "GCLogInToolBar.h"
#import "GCRedToolBarBackgroundView.h"
#import "GCGreenToolBarBackgroundView.h"
#import "UIView+GCImage.h"
#import "AppDelegate.h"

static NSString * const GCValidEmailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

@interface GCLogInViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *connectControls;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *logInControls;
@property (strong, nonatomic) GCLogInToolBar *inputAccessoryView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;

- (IBAction)didTapDismissButton:(UIButton *)button;
- (IBAction)didTapEmailButton:(UIButton *)button;
- (IBAction)didTapFacebookButton:(UIButton *)button;
- (IBAction)didTapTwitterButton:(UIButton *)button;
- (IBAction)logInTextFieldDidBeginEditing:(UITextField *)textField;
- (IBAction)validateLogIn:(UITextField *)textField;
- (IBAction)didTapLogInButton:(UIButton *)button;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeTableView;

@end

@implementation GCLogInViewController

#pragma mark - GCLogInViewController

- (GCLogInToolBar *)inputAccessoryView {
    if (!_inputAccessoryView) {
        _inputAccessoryView = [GCLogInToolBar new];
        [_inputAccessoryView sizeToFit];
    }
    
    return _inputAccessoryView;
}

- (IBAction)didTapDismissButton:(UIButton *)button {
    [self.view endEditing:YES];
    
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *view in self.logInControls) {
            view.alpha = 0.f;
        }
        
        for (UIView *view in self.connectControls) {
            view.alpha = 1.f;
        }
    }];
}

- (IBAction)didTapEmailButton:(UIButton *)button {
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *view in self.connectControls) {
            view.alpha = 0.f;
        }
        
        for (UIView *view in self.logInControls) {
            view.alpha = 1.f;
        }
    }];
}

- (IBAction)didTapFacebookButton:(UIButton *)button {
    NSArray *permissions = @[ @"email", @"publish_actions" ];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil)];
        
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to log in with Facebook", nil)];
            return;
            
        } else if (user.isNew) {            
            [SVProgressHUD setStatus:NSLocalizedString(@"Signing up...", nil)];
            
            PF_FBRequest *request = [PF_FBRequest requestForMe];
            
            [request startWithCompletionHandler:^(PF_FBRequestConnection *connection, PF_FBGraphObject<PF_FBGraphUser> *me, NSError *error) {
                if (!me) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to retrieve basic info", nil)];
                    return;
                }
                
                [PFUser currentUser][@"fbId"] = me.id;
                [PFUser currentUser][@"firstName"] = me.first_name;
                [PFUser currentUser][@"lastName"] = me.last_name;
                [PFUser currentUser][@"gender"] = [me objectForKey:@"gender"];
                [PFUser currentUser].username = [PFUser currentUser].email = [me objectForKey:@"email"];
                NSString *photoURLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", me.username];
                
                [[PFUser currentUser] saveEventually];
                
                [SVProgressHUD dismiss];
                [self performSegueWithIdentifier:GCSignUpSegueIdentifier sender:photoURLString];
            }];
            
        } else {
            NSArray *sports = [user objectForKey:@"sports"];
            
            [[NSUserDefaults standardUserDefaults] setObject:sports forKey:@"sports"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:GCLoggedInSegueIdentifier sender:self];
        }
    }];
}

- (IBAction)didTapTwitterButton:(UIButton *)button {
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (!user) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to log in with Twitter", nil)];
            return;
        }
        
        if (user.isNew) {
            [[GCTwitterAPIClient sharedClient] verifyCredentialsWithBlock:^(NSDictionary *credentials, NSError *error) {
                if (!credentials) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to verify credentials", nil)];
                    return;
                }
                
                NSString *twId = [credentials valueForKeyPath:@"id_str"];
                NSString *name = [credentials valueForKeyPath:@"name"];
                NSArray *names = [name componentsSeparatedByString:@" "];
                NSString *firstName = [names objectAtIndex:0];
                NSString *lastName = names.lastObject;
                NSString *photoURLString = [credentials valueForKeyPath:@"profile_image_url"];
                
                [[PFUser currentUser] setObject:twId forKey:@"twId"];
                [[PFUser currentUser] setObject:firstName forKey:@"firstName"];
                [[PFUser currentUser] setObject:lastName forKey:@"lastName"];
                
                [[PFUser currentUser] saveEventually];
                
                [SVProgressHUD dismiss];
                
                [self performSegueWithIdentifier:GCSignUpSegueIdentifier sender:photoURLString];
            }];
            
        } else {
            NSArray *sports = [user objectForKey:@"sports"];
            
            [[NSUserDefaults standardUserDefaults] setObject:sports forKey:@"sports"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self performSegueWithIdentifier:GCLoggedInSegueIdentifier sender:self];
        }
        
        ACAccountStore *store = [[ACAccountStore alloc] init];
        ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        [store requestAccessToAccountsWithType:type withCompletionHandler:^(BOOL granted, NSError *error) {
            if (!granted) {
                TFLog(@"%@", error);
                return;
            }
            
            ACAccount *account = [[ACAccount alloc] initWithAccountType:type];
            ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:[PFTwitterUtils twitter].authToken tokenSecret:[PFTwitterUtils twitter].authTokenSecret];
            
            account.credential = credential;
            
            [store saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                if (!success && error.code != ACErrorAccountAlreadyExists) {
                    TFLog(@"%@", error);
                }
            }];
        }];
    }];
}

- (IBAction)logInTextFieldDidBeginEditing:(UITextField *)textField {
    [self validateLogIn:textField];
}

- (IBAction)validateLogIn:(UITextField *)textField {    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", GCValidEmailRegex];
    
    BOOL isValidEmail = [predicate evaluateWithObject:self.emailTextField.text];
    BOOL isValidPassword = self.passwordTextField.text.length > 5;
    
    self.logInButton.enabled = isValidEmail && isValidPassword && [UIApplication sharedApplication].delegate;
    
    NSString *text = self.inputAccessoryView.titleLabel.text;
    UIImage *backgroundImage;
    
    if (textField == self.emailTextField) {
        text = isValidEmail ? NSLocalizedString(@"Valid email address", nil) : NSLocalizedString(@"Invalid email address", nil);
        backgroundImage = isValidEmail ? [GCGreenToolBarBackgroundView sharedView].image : [GCRedToolBarBackgroundView sharedView].image;
    } else {
        text = isValidPassword ? NSLocalizedString(@"Valid password", nil) : NSLocalizedString(@"You must use at least 6 characters", nil);
        backgroundImage = isValidPassword ? [GCGreenToolBarBackgroundView sharedView].image : [GCRedToolBarBackgroundView sharedView].image;
    }
    
    self.inputAccessoryView.titleLabel.text = text;
    
    [self.inputAccessoryView setBackgroundImage:backgroundImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
}

- (IBAction)didTapLogInButton:(UIButton *)button {    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", nil)];
    
    [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (error.code != kPFErrorObjectNotFound) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to log in with email", nil)];
                return;
            }
            
            PSAlertView *alertView = [PSAlertView alertWithTitle:NSLocalizedString(@"GameCall Social Sports", nil) message:NSLocalizedString(@"A GameCall user matching these credentials could not be found. Would you like to sign up for a new account, using these credentials?", nil)];
            
            [alertView setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:^{
                [SVProgressHUD dismiss];
            }];
            
            [alertView addButtonWithTitle:NSLocalizedString(@"Sign up", nil) block:^{                    
                PFUser *user = [PFUser user];
                user.username = user.email = self.emailTextField.text;
                user.password = self.passwordTextField.text;
                
                [SVProgressHUD setStatus:NSLocalizedString(@"Signing up...", nil)];
                
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Unable to sign up with email", nil)];
                        return;
                    }
                    
                    [[PFUser currentUser] saveEventually];
                    
                    [SVProgressHUD dismiss];
                    
                    [self performSegueWithIdentifier:GCSignUpSegueIdentifier sender:nil];
                }];
            }];
            
            [alertView show];
            return;
        }
        
        NSArray *sports = [user objectForKey:@"sports"];
        
        [[NSUserDefaults standardUserDefaults] setObject:sports forKey:@"sports"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [SVProgressHUD dismiss];
        [self performSegueWithIdentifier:GCLoggedInSegueIdentifier sender:self];
    }];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.facebookButton.enabled = self.twitterButton.enabled = isReachable;
    [self validateLogIn:nil];
}

- (void)customizeTableView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeTableView];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    [self setConnectControls:nil];
    [self setFacebookButton:nil];
    [self setTwitterButton:nil];
    [self setLogInControls:nil];
    [self setInputAccessoryView:nil];
    [self setEmailTextField:nil];
    [self setPasswordTextField:nil];
    [self setLogInButton:nil];

    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSString *)photoURLString {
    if (![segue.identifier isEqualToString:GCSignUpSegueIdentifier]) {
        return;
    }
    
    [segue.destinationViewController setPhotoURLString:photoURLString];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
