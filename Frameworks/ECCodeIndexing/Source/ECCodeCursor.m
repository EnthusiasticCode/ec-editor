//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"
#import "ECCodeCursor(Private).h"
#import "ECCodeUnit.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeCursor ()
{
    @private
    NSUInteger hash_;
    ECCodeUnit *codeUnit_;
    NSString *language_;
    ECCodeCursorKind kind_;
    NSString *detailedKind_;
    NSString *spelling_;
    NSURL *fileURL_;
    NSUInteger offset_;
    NSRange extent_;
    NSString *unifiedSymbolResolution_;
}
@property (nonatomic, retain) ECCodeUnit *codeUnit;
@end

@implementation ECCodeCursor

@synthesize codeUnit = codeUnit_;
@synthesize language = language_;
@synthesize kind = kind_;
@synthesize detailedKind = detailedKind_;
@synthesize spelling = spelling_;
@synthesize fileURL = fileURL_;
@synthesize offset = offset_;
@synthesize extent = extent_;
@synthesize unifiedSymbolResolution = unifiedSymbolResolution_;

- (id)initWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    self = [super init];
    if (!self)
        return nil;
    language_ = [language copy];
    kind_ = kind;
    detailedKind_ = [detailedKind copy];
    spelling_ = [spelling copy];
    fileURL_ = [fileURL copy];
    offset_ = offset;
    extent_ = extent;
    unifiedSymbolResolution_ = [unifiedSymbolResolution copy];
    return self;
}

+ (id)cursorWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind detailedKind:(NSString *)detailedKind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    id cursor = [self alloc];
    cursor = [cursor initWithLanguage:language kind:kind detailedKind:detailedKind spelling:spelling fileURL:fileURL offset:offset extent:extent unifiedSymbolResolution:unifiedSymbolResolution];
    return [cursor autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSUInteger)hash
{
    return hash_;
}

- (NSUInteger)computeHash
{
    const NSUInteger propertyCount = 9;
    NSUInteger propertyHashes[9] = { [language_ hash], kind_, [detailedKind_ hash], [spelling_ hash], [fileURL_ hash], offset_, extent_.location, extent_.length, [unifiedSymbolResolution_ hash]};
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeCursor *otherCursor = other;
    if (!otherCursor.offset == offset_)
        return NO;
    if (!otherCursor.kind == kind_)
        return NO;
    NSRange otherCursorExtent = otherCursor.extent;
    if (!otherCursorExtent.location == extent_.location)
        return NO;
    if (!otherCursorExtent.length == extent_.length)
        return NO;
    if (language_ || otherCursor.language)
        if (![otherCursor.language isEqual:language_])
            return NO;
    if (detailedKind_ || otherCursor.detailedKind)
        if (![otherCursor.detailedKind isEqual:detailedKind_])
            return NO;
    if (spelling_ || otherCursor.spelling)
        if (![otherCursor.spelling isEqual:spelling_])
            return NO;
    if (fileURL_ || otherCursor.fileURL)
        if (![otherCursor.fileURL isEqual:fileURL_])
            return NO;
    if (unifiedSymbolResolution_ || otherCursor.unifiedSymbolResolution)
        if (![otherCursor.unifiedSymbolResolution isEqual:unifiedSymbolResolution_])
            return NO;
    return YES;
}

@end
