//
//  GCPlainTableViewSectionHeaderView.m
//  GameCall
//
//  Created by Nik Macintosh on 2012-08-11.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "GCPlainTableViewSectionHeaderView.h"

@implementation GCPlainTableViewSectionHeaderView

- (id)init {
    self = [super initWithFrame:CGRectMake(0.f, 0.f, 320.f, 30.f)];
    
    if (!self) {
        return nil;
    }
    
    UINib *nib = [UINib nibWithNibName:@"GCPlainTableViewSectionHeaderView" bundle:nil];
    NSArray *views = [nib instantiateWithOwner:self options:nil];
    UIView *view = [views objectAtIndex:0];
    UIImage *backgroundImage = [[UIImage imageNamed:@"tableview-section-header-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    
    view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
    
    [self addSubview:view];
    
    return self;
}

@end
