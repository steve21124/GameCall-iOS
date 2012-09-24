//
//  UIView+GCImage.m
//  GameCall
//
//  Created by Nik Macintosh on 12-06-15.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "UIView+GCImage.h"

@implementation UIView (GCImage)

- (UIImage *)image {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
