//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"


@implementation ECCodeCursor

@synthesize language;
@synthesize kind;
@synthesize detailedKind;
@synthesize spelling;
@synthesize fileURL;
@synthesize offset;
@synthesize extent;
@synthesize unifiedSymbolResolution;

- (id)initWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    return nil;
}

+ (id)cursorWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    id cursor = [self alloc];
    cursor = [cursor initWithLanguage:language kind:kind detailedKind:detailedKind spelling:spelling fileURL:fileURL offset:offset extent:extent unifiedSymbolResolution:unifiedSymbolResolution];
    return [cursor autorelease];
}

@end
