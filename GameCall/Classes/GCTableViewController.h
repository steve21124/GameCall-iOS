//
//  GCTableViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 2012-07-29.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GCTableViewController : UITableViewController

@property (strong, nonatomic) UIView *emptyView;
@property (strong, nonatomic) IBOutlet UIButton *emptyViewIconButton;
@property (strong, nonatomic) IBOutlet UIButton *emptyViewLabelButton;
@property (assign, nonatomic) BOOL showsEmptyView;

- (IBAction)didTapEmptyViewButton;
- (UIButton *)detailDisclosureButton;

@end
