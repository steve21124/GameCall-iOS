//
//  GCSettingsViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-06.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

enum {
    GCSettingsTableViewSectionGeneral = 0,
    GCSettingsTableViewSectionAbout,
    GCSettingsTableViewSectionLegal
};

typedef NSInteger GCSettingsTableViewSection;

@interface GCSettingsViewController : UITableViewController

@end
