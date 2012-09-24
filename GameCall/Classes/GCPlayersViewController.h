//
//  GCPlayersViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-24.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;

@interface GCPlayersViewController : UITableViewController

@property (strong, nonatomic) PFObject *game;

@end
