//
//  GCVenueTableViewCell.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCVenueTableViewCell.h"

@implementation GCVenueTableViewCell

#pragma mark - GCVenueTableViewCell

- (void)setVenue:(PFObject *)venue {
    self.nameLabel.text = [venue objectForKey:@"name"];
    self.addressLabel.text = [venue objectForKey:@"address"];
    
    [self setNeedsDisplay];
}

@end
