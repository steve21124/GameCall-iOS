//
//  ABPerson.m
//  GameCall
//
//  Created by Nik Macintosh on 12-07-10.
//  Copyright (c) 2012 GameCall Social Sports. All rights reserved.
//

#import "ABPerson.h"

@interface ABPerson ()

- (NSArray *)arrayForRecord:(ABRecordRef)record property:(ABMultiValueIdentifier)property;

@end

@implementation ABPerson

#pragma mark - ABPerson

+ (void)peopleWithBlock:(void (^)(NSArray *people))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ABAddressBookRef addressBook = ABAddressBookCreate();
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef records = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, ABPersonGetSortOrdering());
        CFIndex recordsCount = CFArrayGetCount(records);
        NSMutableArray *people = [NSMutableArray arrayWithCapacity:recordsCount];
        
        for (CFIndex i = 0; i < recordsCount; i++) {
            ABRecordRef record = CFArrayGetValueAtIndex(records, i);
            ABPerson *person = [[ABPerson alloc] initWithRecord:record];
            
            [people addObject:person];
        }
        
        CFRelease(addressBook);
        CFRelease(source);
        CFRelease(records);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (block) {
                block([NSArray arrayWithArray:people]);
            }
        });
    });
}

+ (void)reachablePeopleWithBlock:(void (^)(NSArray *people))block {
    [ABPerson peopleWithBlock:^(NSArray *people) {
        NSArray *reachablePeople = [people filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"phones != NIL || emails != NIL"]];
        
        if (block) {
            block(reachablePeople);
        }
    }];
}

- (id)initWithRecord:(ABRecordRef)record {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSData *imageData = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail);
    
    _image = [UIImage imageWithData:imageData];
    _firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    _lastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
    _compositeName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(record);
    _phones = [self arrayForRecord:record property:kABPersonPhoneProperty];
    _emails = [self arrayForRecord:record property:kABPersonEmailProperty];
    
    return self;
}

- (NSArray *)arrayForRecord:(ABRecordRef)record property:(ABMultiValueIdentifier)property {
    CFTypeRef value = ABRecordCopyValue(record, property);
    
    if (value == NULL) {
        return nil;
    }
    
    CFArrayRef references = ABMultiValueCopyArrayOfAllValues(value);
    
    if (references == NULL) {
        CFRelease(value);
        return nil;
    }
    
    CFIndex referencesCount = CFArrayGetCount(references);
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:referencesCount];
    
    for (CFIndex i = 0; i < referencesCount; i++) {
        CFStringRef reference = CFArrayGetValueAtIndex(references, i);
        
        [mutableArray addObject:(__bridge_transfer NSString *)reference];
    }
    
    CFRelease(references);
    
    return [mutableArray copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: image:%@ firstName: %@, lastName: %@, compositeName: %@, phones: %@, emails: %@>", NSStringFromClass([self class]), self.image, self.firstName, self.lastName, self.compositeName, self.phones, self.emails];
}

@end
