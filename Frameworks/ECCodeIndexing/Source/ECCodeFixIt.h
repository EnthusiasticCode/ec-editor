//
//  ECCodeFixIt.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECCodeFixIt : NSObject
{
    NSUInteger _hash;
}
@property (nonatomic, readonly, copy) NSString *string;
@property (nonatomic, readonly, copy) NSURL *fileURL;
@property (nonatomic, readonly) NSRange replacementRange;

- (id)initWithString:(NSString *)string fileURL:(NSURL *)fileURL replacementRange:(NSRange)replacementRange;
+ (id)fixItWithString:(NSString *)string fileURL:(NSURL *)fileURL replacementRange:(NSRange)replacementRange;

@end
