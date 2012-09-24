//
//  GCGamesScrollViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-06.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGamesScrollViewController.h"
#import "GCMyGamesViewController.h"

static NSString * const kGCMyGamesViewControllerIdentifier = @"GCMyGamesViewController";
static NSString * const kGCGameFindViewControllerIdentifier = @"GCGameFindViewController";

@interface GCGamesScrollViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet GCMyGamesViewController *leftViewController;
@property (strong, nonatomic) IBOutlet UIViewController *rightViewController;

- (void)customizeTabBarItem;
- (void)customizeBackgroundImage;
- (void)customizeLeftViewController;
- (void)customizeRightViewController;

@end

@implementation GCGamesScrollViewController

#pragma mark - GCGamesScrollViewController

- (GCMyGamesViewController *)leftViewController {
    if (!_leftViewController) {
        _leftViewController = [self.storyboard instantiateViewControllerWithIdentifier:kGCMyGamesViewControllerIdentifier];
    }
    
    return _leftViewController;
}

- (UIViewController *)rightViewController {
    if (!_rightViewController) {
        _rightViewController = [self.storyboard instantiateViewControllerWithIdentifier:kGCGameFindViewControllerIdentifier];
    }
    
    return _rightViewController;
}

- (void)customizeTabBarItem {
    UIImage *selectedImage = [UIImage imageNamed:@"games-selected"];
    UIImage *unselectedImage = [UIImage imageNamed:@"games-normal"];
    
    self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:nil tag:0];
    [self.navigationController.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
    [self.navigationController.tabBarItem setImageInsets:UIEdgeInsetsMake(5.f, 0.f, -5.f, 0.f)];
}

- (void)customizeBackgroundImage {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.scrollView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

- (void)customizeLeftViewController {
    [self addChildViewController:self.leftViewController];
    [self.leftViewController didMoveToParentViewController:self];
    [self.scrollView addSubview:self.leftViewController.view];
}

- (void)customizeRightViewController {
    [self addChildViewController:self.rightViewController];
    [self.rightViewController didMoveToParentViewController:self];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSInteger currentPage = self.pageControl.currentPage;
    NSInteger nextPage = currentPage ^ 1;
    CGRect frame = self.view.frame;
    UIViewController *to = [self.childViewControllers objectAtIndex:nextPage];
    
    to.view.frame = CGRectMake(frame.size.width * nextPage, frame.origin.y, frame.size.width, frame.size.height);
    [self.scrollView addSubview:to.view];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    self.pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger previousPage = self.pageControl.currentPage ^ 1;
    NSInteger currentPage = self.pageControl.currentPage;
    UIViewController *from = [self.childViewControllers objectAtIndex:previousPage];
    UIViewController *to = [self.childViewControllers objectAtIndex:currentPage];
    
    [from.view removeFromSuperview];
    
    if ([to isKindOfClass:[GCMyGamesViewController class]]) {
        [self.navigationItem setLeftBarButtonItem:to.editButtonItem animated:YES];
        [self.navigationItem setRightBarButtonItem:[(GCMyGamesViewController *)to addButtonItem] animated:YES];
    } else {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
    
    self.navigationItem.title = to.title;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeBackgroundImage];
    [self customizeLeftViewController];
    [self customizeRightViewController];
    
    self.navigationItem.title = self.leftViewController.title;
    self.navigationItem.leftBarButtonItem = self.leftViewController.editButtonItem;
    self.navigationItem.rightBarButtonItem = self.leftViewController.addButtonItem;
}

- (void)viewDidUnload {
    [self setPageControl:nil];
    [self setScrollView:nil];
    [self setLeftViewController:nil];
    [self setRightViewController:nil];
    
    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
        
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * 2.f, self.view.frame.size.height);
    self.leftViewController.view.frame = self.view.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
    return YES;
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
