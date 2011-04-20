//
//  ECTextDocument.m
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextDocument.h"


@implementation ECTextDocument

@synthesize text = text_;

- (void)setText:(NSString *)text
{
    if (![text_ isEqualToString:text])
        self.documentEdited = YES;
    [text_ autorelease];
    text_ = [text retain];
}

- (void)dealloc
{
    self.text = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
        self.text = @"";
    return self;
}

- (BOOL)readFromPath:(NSString *)path error:(NSError **)error
{
    self.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    return YES;
}

- (BOOL)writeToPath:(NSString *)path error:(NSError **)error
{
    [self.text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:error];
    return YES;
}

@end
