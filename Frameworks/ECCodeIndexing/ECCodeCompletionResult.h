//
//  ECCodeCompletionResult.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeCompletionString;

@interface ECCodeCompletionResult : NSObject
{
    NSUInteger _hash;
}
// currently unused, reimplement as enum when we figure out something to do with it
@property (nonatomic,readonly) int cursorKind;
@property (nonatomic,readonly, copy) ECCodeCompletionString *completionString;

- (id)initWithCursorKind:(int)cursorKind completionString:(ECCodeCompletionString *)completionString;
- (id)initWithCompletionString:(ECCodeCompletionString *)completionString;

+ (id)resultWithCursorKind:(int)cursorKind completionString:(ECCodeCompletionString *)completionString;
+ (id)resultWithCompletionString:(ECCodeCompletionString *)completionString;

@end
