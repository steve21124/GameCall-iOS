//
//  GCSportsViewController.h
//  GameCall
//
//  Created by Nik Macintosh on 12-06-23.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSMutableOrderedSet (GCQueueAdditions)

- (void)enqueue:(id)object;
- (id)dequeue;

@end

@interface GCSportsViewController : UIViewController

@end
