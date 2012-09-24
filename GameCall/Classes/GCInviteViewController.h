//
//  GCInviteViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-21.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    GCInviteViewControllerSegmentIndexFacebook = 0,
    GCInviteViewControllerSegmentIndexTwitter,
    GCInviteViewControllerSegmentIndexContacts
};

typedef NSInteger GCInviteViewControllerSegmentIndex;

@interface GCInviteViewController : UIViewController

@end
