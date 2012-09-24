//
//  GCVenueTableViewCell.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;

@interface GCVenueTableViewCell : UITableViewCell

@property (strong, nonatomic) PFObject *venue;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;

@end
