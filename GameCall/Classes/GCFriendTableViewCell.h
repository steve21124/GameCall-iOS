//
//  GCFriendTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;
@class GCImageView;

@interface GCFriendTableViewCell : UITableViewCell

@property (strong, nonatomic) PFUser *friend;
@property (strong, nonatomic) IBOutlet GCImageView *parseImageView;
@property (strong, nonatomic) IBOutlet UILabel *compositeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *friendsCountLabel;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *sportsIndicators;

@end
