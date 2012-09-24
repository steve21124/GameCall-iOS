//
//  AppDelegate.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-22.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "TestFlight.h"
#import "UIView+GCImage.h"
#import "GCNavigationBarBackgroundView.h"
#import "GCBackButtonBackgroundView.h"
#import "GCBarButtonBackgroundView.h"
#import "GCToolbarBackgroundView.h"
#import "GCTabBarBackgroundView.h"
#import "GCTabBarSelectionIndicatorView.h"
#import "PFUser+GCAdditions.h"

@interface AppDelegate ()

- (void)reachabilityDidChange:(NSNotification *)notification;

- (void)customizeNavigationBar;
- (void)customizeBackBarButtonItem;
- (void)customizeBarButtonItem;
- (void)customizeSearchBar;
- (void)customizeToolbar;
- (void)customizeSegmentedControl;
- (void)customizeTabBar;
- (void)customizeAppearance;

@end

@implementation AppDelegate

@synthesize reachability = _reachability;

#pragma mark - AppDelegate

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityForInternetConnection];
    }
    
    return _reachability;
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    if (reachability.currentReachabilityStatus == NotReachable) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Network connection unavailable", nil)];
    }
}

- (void)customizeNavigationBar {
    [[UINavigationBar appearance] setBackgroundImage:[GCNavigationBarBackgroundView sharedView].image forBarMetrics:UIBarMetricsDefault];
}

- (void)customizeBackBarButtonItem {
    UIImage *backButtonBackgroundImage = [[GCBackButtonBackgroundView sharedView].image resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 13.f, 0.f, 5.f)];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)customizeBarButtonItem {
    UIImage *barButtonBackgroundImage = [[GCBarButtonBackgroundView sharedView].image resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f)];
    
    [[UIBarButtonItem appearance] setBackgroundImage:barButtonBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)customizeSearchBar {
    [[UISearchBar appearance] setBackgroundImage:[GCToolbarBackgroundView sharedView].image];
}

- (void)customizeToolbar {
    [[UIToolbar appearance] setBackgroundImage:[GCToolbarBackgroundView sharedView].image forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
}

- (void)customizeSegmentedControl {
    UIImage *segmentedControlBackgroundImage = [[GCBarButtonBackgroundView sharedView].image resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f)];
    
    [[UISegmentedControl appearance] setBackgroundImage:segmentedControlBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)customizeTabBar {
    [[UITabBar appearance] setBackgroundImage:[GCTabBarBackgroundView sharedView].image];
    [[UITabBar appearance] setSelectionIndicatorImage:[GCTabBarSelectionIndicatorView sharedView].image];
}

- (void)customizeAppearance {
    [self customizeNavigationBar];
    [self customizeBackBarButtonItem];
    [self customizeBarButtonItem];
    [self customizeSearchBar];
    [self customizeToolbar];
    [self customizeSegmentedControl];
    [self customizeTabBar];
}

#pragma mark - PFFacebookUtils

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

#pragma mark - PFPush

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];
    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            TFLog(@"%@", @"Successfully subscribed to the broadcast channel");
        } else
            TFLog(@"%@", @"Failed to subscribe to the broadcast channel");
    }];
}

#define kGCRemoteNotificationsNotSupportedInSimulatorErrorCode 3010

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == kGCRemoteNotificationsNotSupportedInSimulatorErrorCode) {
        return;
    }
    
    TFLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    TFLog(@"%@", userInfo);
    
    [PFPush handlePush:userInfo];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [self.reachability startNotifier];
    
    [TestFlight takeOff:GCTestFlightTeamToken];
    
    [Parse setApplicationId:GCParseApplicationId clientKey:GCParseClientKey];
    
    [PFFacebookUtils initializeWithApplicationId:GCFacebookApplicationId];
    
    [PFTwitterUtils initializeWithConsumerKey:GCTwitterConsumerKey consumerSecret:GCTwitterConsumerSecret];
    
    [PFUser enableAutomaticUser];
    
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    [self customizeAppearance];
    
    BOOL hasEmail = !![[PFUser currentUser] objectForKey:@"email"];
    BOOL hasFirstName = !![[PFUser currentUser] objectForKey:@"firstName"];
    BOOL hasLastName = !![[PFUser currentUser] objectForKey:@"lastName"];
    BOOL hasSports = !![[NSUserDefaults standardUserDefaults] arrayForKey:@"sports"];
    BOOL isFinishedSignUpProcess = hasEmail && hasFirstName && hasLastName && hasSports;
    
    if (![PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]] && isFinishedSignUpProcess) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:GCMainStoryboardIdentifier bundle:nil];
        UITabBarController *tabBarController = [mainStoryboard instantiateViewControllerWithIdentifier:GCTabBarControllerIdentifier];
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        
        [navigationController pushViewController:tabBarController animated:NO];
    }
    
    if (!isFinishedSignUpProcess) {
        [[PFUser currentUser] logOutFromGameCall];
        [[PFUser currentUser] deleteEventually];
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
