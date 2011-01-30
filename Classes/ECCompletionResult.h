//
//  ECCompletionResult.h
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCompletionString;

@interface ECCompletionResult : NSObject {

}
// currently unused, reimplement as enum when we figure out something to do with it
@property (nonatomic,readonly) int cursorKind;
@property (nonatomic,readonly) ECCompletionString *completionString;

- (id)initWithCursorKind:(int)cursorKind completionString:(ECCompletionString *)completionString;
- (id)initWithCompletionString:(ECCompletionString *)completionString;

@end
