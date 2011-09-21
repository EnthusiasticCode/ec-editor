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
@property (nonatomic,readonly) ECCodeCursorKind cursorKind;
@property (nonatomic,readonly, strong) ECCodeCompletionString *completionString;

@end
