//
//  ECCodeCompletionString.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Object representing any possible completion. */
@interface ECCodeCompletionString : NSObject {
    
}
/*! The chance of the completion being the correct one. 0 < priority < 1. */
@property (nonatomic) float priority;
/*! The range of the characters that need to be replaced by the completion. */
@property (nonatomic) NSRange replacementRange;
/*! A short description of the completion. */
@property (nonatomic, retain) NSString *label;
/*! The string the completion will insert into the target text. */
@property (nonatomic, retain) NSString *string;
/*! Additional information about the completion to be displayed to the user. */
@property (nonatomic, retain) NSString *note;

+ (ECCodeCompletionString *)completionWithReplacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string;

- (ECCodeCompletionString *)initWithPriority:(float)priority replacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string note:(NSString *)note;
- (ECCodeCompletionString *)initWithReplacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string;

@end
