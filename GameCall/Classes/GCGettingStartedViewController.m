//
//  GCGettingStartedViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-07-29.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGettingStartedViewController.h"
#import "AppDelegate.h"

static NSString * const GCGotStartedSegueIdentifier = @"GCGotStartedSegue";

@interface GCGettingStartedViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSArray *pages;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

- (IBAction)didTapStartButton:(UIButton *)button;

- (void)customizeView;

@end

@implementation GCGettingStartedViewController

#pragma mark - GCGettingStartedViewController

- (IBAction)didTapStartButton:(UIButton *)button {
    
    if (self.navigationController == [(AppDelegate *)[UIApplication sharedApplication].delegate window].rootViewController) {
        [self performSegueWithIdentifier:GCGotStartedSegueIdentifier sender:self];
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)customizeView {
    UIImage *backgroundImage = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsZero];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    self.pageControl.currentPage = page;
}

#pragma mark - UIViewController

- (void)loadView {
    [super loadView];
    
    UINib *nib = [UINib nibWithNibName:@"GCGettingStartedPageViews" bundle:nil];
    
    self.pages = [nib instantiateWithOwner:self options:nil];
    self.pages = [self.pages sortedArrayUsingComparator:^NSComparisonResult(UIView *page, UIView *otherPage) {
        return page.tag > otherPage.tag;
    }];
    
    [self.pages enumerateObjectsUsingBlock:^(UIView *page, NSUInteger idx, BOOL *stop) {
        CGRect frame = page.frame;
        
        frame.origin = CGPointMake(idx * frame.size.width, 0.f);
        page.frame = frame;
        
        [self.scrollView addSubview:page];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeView];
}

- (void)viewDidUnload {
    [self setScrollView:nil];
    [self setPages:nil];
    [self setPageControl:nil];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(self.pages.count * self.view.frame.size.width, self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
