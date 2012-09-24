//
//  GCInviteTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-24.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCImageView.h"

@interface GCInviteTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GCImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
