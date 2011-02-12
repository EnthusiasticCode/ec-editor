//
//  ECDocument.m
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDocument.h"


@implementation ECDocument

@synthesize fileURL = _fileURL;
@synthesize fileType = _fileType;
@synthesize fileModificationDate = _fileModificationDate;
@synthesize documentEdited = _documentEdited;

- (NSString *)displayName
{
    return [self.fileURL lastPathComponent];
}

- (void)dealloc
{
    self.fileURL = nil;
    self.fileType = nil;
    self.fileModificationDate = nil;
    [super dealloc];
}

- (id)initWithType:(NSString *)fileType error:(NSError **)error
{
    self = [self init];
    self.fileType = fileType;
    return self;
}

- (id)initWithContentsOfURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    self = [self init];
    [self readFromURL:fileURL ofType:fileType error:error];
    self.fileURL = fileURL;
    self.fileType = fileType;
    self.fileModificationDate = [NSDate date];
    return self;
}

- (BOOL)readFromURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:fileURL options:0 error:error];
    BOOL result = [self readFromFileWrapper:fileWrapper ofType:fileType error:error];
    [fileWrapper release];
    return result;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)fileType error:(NSError **)error
{
    return [self readFromData:[fileWrapper regularFileContents] ofType:fileType error:error];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)fileType error:(NSError **)error
{
    return NO;
}

- (BOOL)writeToURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    NSFileWrapper *fileWrapper = [self fileWrapperOfType:fileType error:error];
    if (fileWrapper)
    {
        [fileWrapper writeToURL:fileURL options:0 originalContentsURL:self.fileURL error:error];
        return YES;
    }
    return NO;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)fileType error:(NSError **)error
{
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[self dataOfType:fileType error:error]];
    return [fileWrapper autorelease];
}

- (NSData *)dataOfType:(NSString *)fileType error:(NSError **)error
{
    return nil;
}

+ (BOOL)isNativeType:(NSString *)fileType
{
    return NO;
}

+ (NSArray *)readableTypes
{
    return [NSArray array];
}

+ (NSArray *)writableTypes
{
    return [NSArray array];
}

@end
