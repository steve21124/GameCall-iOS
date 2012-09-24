//
//  GCAddFriendTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-07.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;
@class GCImageView;

@interface GCAddFriendTableViewCell : UITableViewCell

@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) IBOutlet GCImageView *parseImageView;
@property (strong, nonatomic) IBOutlet UILabel *compositeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *friendsCountLabel;

@end
