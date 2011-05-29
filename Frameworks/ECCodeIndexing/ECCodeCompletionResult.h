//
//  ECCodeCompletionResult.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeCursor.h"
@class ECCodeCompletionString;

@interface ECCodeCompletionResult : NSObject
{
    NSUInteger _hash;
}
// currently unused, reimplement as enum when we figure out something to do with it
@property (nonatomic,readonly) ECCodeCursorKind cursorKind;
@property (nonatomic,readonly, copy) ECCodeCompletionString *completionString;

- (id)initWithCursorKind:(ECCodeCursorKind)cursorKind completionString:(ECCodeCompletionString *)completionString;
- (id)initWithCompletionString:(ECCodeCompletionString *)completionString;

+ (id)resultWithCursorKind:(ECCodeCursorKind)cursorKind completionString:(ECCodeCompletionString *)completionString;
+ (id)resultWithCompletionString:(ECCodeCompletionString *)completionString;

@end
