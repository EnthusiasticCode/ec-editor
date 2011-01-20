//
//  ECCodeViewCompletion.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewCompletion.h"


@implementation ECCodeViewCompletion

@synthesize priority = _priority;
@synthesize replacementRange = _replacementRange;
@synthesize label = _label;
@synthesize string = _string;
@synthesize note = _note;

+ (ECCodeViewCompletion *)completionWithReplacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string
{
    return [[[self alloc] initWithReplacementRange:replacementRange label:label string:string] autorelease];
}

- (ECCodeViewCompletion *)initWithPriority:(float)priority replacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string note:(NSString *)note
{
    self = [super init];
    if (self)
    {
        self.priority = priority;
        self.replacementRange = replacementRange;
        self.label = label;
        self.string = string;
        self.note = note;
    }
    return self;
}

- (ECCodeViewCompletion *)initWithReplacementRange:(NSRange)replacementRange label:(NSString *)label string:(NSString *)string
{
    return [self initWithPriority:0.0 replacementRange:replacementRange label:label string:string note:nil];
}

@end
