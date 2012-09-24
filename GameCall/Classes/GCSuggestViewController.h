//
//  GCSuggestViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-18.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import "GCTableViewController.h"

enum {
    GCSuggestTableViewSectionFacebook = 0,
    GCSuggestTableViewSectionTwitter,
    GCSuggestTableViewSectionContacts,
    GCSuggestTableViewSectionCount
};

typedef NSInteger GCSuggestTableViewSection;

@interface GCSuggestViewController : GCTableViewController

@end
