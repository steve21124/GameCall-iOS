//
//  NSArray+Flatten.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-18.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "NSArray+Flatten.h"

@implementation NSArray (Flatten)

- (NSArray *)flatten {
    NSMutableArray *flattened = [NSMutableArray array];
    
    for (id obj in self) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [flattened addObjectsFromArray:obj];
        }
    }
    
    return [NSArray arrayWithArray:flattened];
}

@end
