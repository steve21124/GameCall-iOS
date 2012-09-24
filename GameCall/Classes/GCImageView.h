//
//  GCImageView.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-17.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <UIKit/UIkit.h>
#import <QuartzCore/QuartzCore.h>

@interface GCImageView : PFImageView

- (CGFloat)borderWidth;
- (void)setBorderWidth:(CGFloat)borderWidth;

@end
