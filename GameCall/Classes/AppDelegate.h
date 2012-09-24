//
//  AppDelegate.h
//  GameCall
//
//  Created by Nik Macintosh on 12-06-22.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) Reachability *reachability;

@end
