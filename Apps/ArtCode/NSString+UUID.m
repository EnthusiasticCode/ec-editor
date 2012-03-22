//
//  NSString+UUID.m
//  ArtCode
//
//  Created by Uri Baghin on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+UUID.h"


@implementation NSString (UUID)

- (id)initWithGeneratedUUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *string = (__bridge NSString *)uuidString;
    CFRelease(uuidString);
    CFRelease(uuid);
    return string;
}

- (id)initWithGeneratedUUIDForUseAsKeyInDictionary:(NSDictionary *)dictionary {
    NSString *string = nil;
    for (;;) {
        string = [self initWithGeneratedUUID];
        if (![dictionary objectForKey:string]) {
            break;
        }
    }
    return string;
}

- (id)initWithGeneratedUUIDNotContainedInSet:(NSSet *)uuidSet {
    NSString *string = nil;
    for (;;) {
        string = [self initWithGeneratedUUID];
        if (![uuidSet containsObject:string]) {
            break;
        }
    }
    return string;
}

@end
