//
//  GCGameTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-18.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;

@interface GCGameTableViewCell : UITableViewCell

@property (strong, nonatomic) PFObject *game;
@property (strong, nonatomic) IBOutlet UIImageView *sportIndicator;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailsLabel;

@end
