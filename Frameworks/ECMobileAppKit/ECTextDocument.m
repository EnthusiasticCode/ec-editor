//
//  ECTextDocument.m
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextDocument.h"
#import <MobileCoreServices/MobileCoreServices.h>


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

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)fileType error:(NSError **)error
{
    if (!data || ![data bytes])
        return NO;
    self.text = [NSString stringWithUTF8String:[data bytes]];
    self.documentEdited = NO;
    return YES;
}

- (NSData *)dataOfType:(NSString *)fileType error:(NSError **)error
{
    NSData *data = [NSData dataWithBytes:[self.text UTF8String] length:[self.text length]];
    self.documentEdited = NO;
    return data;
}

+ (BOOL)isNativeType:(NSString *)fileType
{
    if (UTTypeConformsTo((CFStringRef)fileType, (CFStringRef)@"public.plain-text"))
        return YES;
    return NO;
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
