//
//  ABPerson.h
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface ABPerson : NSObject

@property (strong, nonatomic, readonly) UIImage *image;
@property (copy, nonatomic, readonly) NSString *firstName;
@property (copy, nonatomic, readonly) NSString *lastName;
@property (copy, nonatomic, readonly) NSString *compositeName;
@property (strong, nonatomic, readonly) NSArray *phones;
@property (strong, nonatomic, readonly) NSArray *emails;

+ (void)peopleWithBlock:(void (^)(NSArray *people))block;
+ (void)reachablePeopleWithBlock:(void (^)(NSArray *people))block;
- (id)initWithRecord:(ABRecordRef)record;

@end
