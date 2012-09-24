//
//  GCSportsViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-23.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCSportsViewController.h"
#import "AppDelegate.h"

static NSInteger const kGCChosenMaximum = 3;

@implementation NSMutableOrderedSet (GCQueueAdditions)

- (void)enqueue:(id)object {
    [self insertObject:object atIndex:0];
}

- (id)dequeue {
    id lastObject = [self lastObject];
    [self removeObjectAtIndex:self.count - 1];
	
    return lastObject;
}

@end

@interface GCSportsViewController ()

@property (strong, nonatomic, readonly) NSOrderedSet *supported;
@property (strong, nonatomic) NSMutableOrderedSet *chosen;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *sportsRadioButtons;

- (IBAction)didTapSportsRadioButton:(UIButton *)selector;

- (void)reachabilityDidChange:(NSNotification *)notification;
- (void)updateInterfaceWithReachability:(Reachability *)reachability;

- (void)customizeNavigationItem;
- (void)customizeBackgroundImage;
- (void)customizeSportsRadioButtons;

@end

@implementation GCSportsViewController

@synthesize supported = _supported;

#pragma mark - GCFocusViewController

- (NSOrderedSet *)supported {
    if (!_supported) {
        _supported = [NSOrderedSet orderedSetWithObjects:@"badminton", @"baseball", @"basketball", @"fitness", @"football", @"golf", @"hockey", @"soccer", @"tennis", @"yoga", nil];
    }
    
    return _supported;
}

- (NSMutableOrderedSet *)chosen {
    if (!_chosen) {
        _chosen = [NSMutableOrderedSet orderedSetWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"sports"]];
    }
    
    return _chosen;
}

- (void)didTapSportsRadioButton:(UIButton *)selector {
    selector.selected = !selector.selected;
    
    NSUInteger index = [self.sportsRadioButtons indexOfObject:selector];
    NSDictionary *sport = [self.supported objectAtIndex:index];
        
    if (selector.selected) {
        [self.chosen enqueue:sport];
    } else {
        [self.chosen removeObject:sport];
    }
    
    if (self.chosen.count > kGCChosenMaximum) {
        NSString *firstSport = [self.chosen dequeue];
        NSUInteger index = [self.supported indexOfObject:firstSport];
        UIButton *selector = [self.sportsRadioButtons objectAtIndex:index];
        
        selector.selected = NO;
    }
    
    [self customizeNavigationItem];
}

- (void)reachabilityDidChange:(NSNotification *)notification {
    Reachability *reachability = notification.object;
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:reachability];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    BOOL isReachable = reachability.currentReachabilityStatus != NotReachable;
    
    self.view.userInteractionEnabled = isReachable;
    self.view.alpha = isReachable ? 1.f : 0.75f;
}

- (void)customizeNavigationItem {
    self.navigationItem.hidesBackButton = self.chosen.count < 1;
}

- (void)customizeBackgroundImage {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

- (void)customizeSportsRadioButtons {    
    self.sportsRadioButtons = [self.sportsRadioButtons sortedArrayUsingComparator:^NSComparisonResult(UIButton *button, UIButton *otherButton) {
        return button.tag > otherButton.tag;
    }];
    
    [self.sportsRadioButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        NSString *sport = [self.supported objectAtIndex:idx];
        
        button.selected = [self.chosen containsObject:sport];
        [button addTarget:self action:@selector(didTapSportsRadioButton:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeNavigationItem];
    [self customizeBackgroundImage];
    [self customizeSportsRadioButtons];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self updateInterfaceWithReachability:appDelegate.reachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidUnload {
    _supported = nil;
    [self setChosen:nil];
    [self setSportsRadioButtons:nil];
    
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSUserDefaults standardUserDefaults] setObject:[self.chosen array] forKey:@"sports"];
    
    if ([[NSUserDefaults standardUserDefaults] synchronize]) {
        [[PFUser currentUser] setObject:[self.chosen array] forKey:@"sports"];
        [[PFUser currentUser] saveEventually];
    }
    
    [super viewWillDisappear:animated];
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
