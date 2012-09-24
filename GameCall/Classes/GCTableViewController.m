//
//  GCTableViewController.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-07-29.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCTableViewController.h"

@interface GCTableViewController ()

- (void)didTapAccessoryButton:(UIButton *)button event:(UIEvent *)event;

@end

@implementation GCTableViewController

#pragma mark - GCTableViewController

- (void)setShowsEmptyView:(BOOL)showsEmptyView {
    _showsEmptyView = showsEmptyView;
    
    if (showsEmptyView) {
        self.editing = NO;
        
        if (self.searchDisplayController) {
            [self.view insertSubview:self.emptyView belowSubview:self.searchDisplayController.searchBar];
            return;
        }
        
        [self.view addSubview:self.emptyView];
    } else {
        [self.emptyView removeFromSuperview];
    }
    
    self.editButtonItem.enabled = !showsEmptyView;
    self.tableView.scrollEnabled = !showsEmptyView;
}

- (IBAction)didTapEmptyViewButton {
    
}

- (UIButton *)detailDisclosureButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = CGRectMake(0.f, 0.f, 23.f, 23.f);
    [button setImage:[UIImage imageNamed:@"detail-disclosure-indicator-right"] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(didTapAccessoryButton:event:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)didTapAccessoryButton:(UIButton *)button event:(UIEvent *)event {
    UITouch *touch = [event touchesForView:button].anyObject;
    CGPoint point = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (!indexPath) {
        return;
    }
    
    [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark - UIViewController

- (void)loadView {
    [super loadView];
    
    UINib *nib = [UINib nibWithNibName:@"GCTableViewControllerEmptyView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:self options:nil];
    
    self.emptyView = [views objectAtIndex:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(reachabilityDidChange:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    }
}

- (void)viewDidUnload {
    [self setEmptyView:nil];
    [self setEmptyViewIconButton:nil];
    [self setEmptyViewLabelButton:nil];
    
    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.emptyView.frame = self.view.frame;
}

#pragma mark - NSObject

- (void)dealloc {
    if ([self respondsToSelector:@selector(reachabilityDidChange:)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    }
}

@end
