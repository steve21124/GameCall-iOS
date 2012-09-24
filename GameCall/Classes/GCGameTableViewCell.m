//
//  GCGameTableViewCell.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-18.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCGameTableViewCell.h"

@implementation GCGameTableViewCell

#pragma mark - GCGameTableViewCell

- (void)setGame:(PFObject *)game {
    _game = game;
    
    UIImage *sportImage = [UIImage imageNamed:[NSString stringWithFormat:@"selector-%@-normal", [game objectForKey:@"sport"]]];
    
    self.sportIndicator.image = sportImage;
    
    PFObject *venue = [game objectForKey:@"venue"];
    
    self.nameLabel.text = [venue objectForKey:@"name"];
}

@end
