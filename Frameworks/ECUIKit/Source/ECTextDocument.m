//
//  ECTextDocument.m
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextDocument.h"


@implementation ECTextDocument

@synthesize text = _text;

- (void)setText:(NSString *)text
{
    if (![_text isEqualToString:text])
        self.documentEdited = YES;
    [_text autorelease];
    _text = [text retain];
}

- (void)dealloc
{
    self.text = nil;
    [super dealloc];
}

- (id)initWithType:(NSString *)fileType error:(NSError **)error
{
    self = [super initWithType:fileType error:error];
    if (self)
        self.text = @"";
    return self;
}

- (BOOL)readFromURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    self.text = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:error];
    return YES;
}

- (BOOL)writeToURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    [self.text writeToURL:fileURL atomically:NO encoding:NSUTF8StringEncoding error:error];
    return YES;
}

+ (NSArray *)readableTypes
{
    return [NSArray arrayWithObject:@"public.plain-text"];
}

+ (NSArray *)writableTypes
{
    return [NSArray arrayWithObject:@"public.plain-text"];
}

@end
