//
//  GCPermissionTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-20.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GCPermissionTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *providerLogoImageView;
@property (strong, nonatomic) IBOutlet UILabel *providerLabel;
@property (strong, nonatomic) IBOutlet UILabel *purposeLabel;

@end
