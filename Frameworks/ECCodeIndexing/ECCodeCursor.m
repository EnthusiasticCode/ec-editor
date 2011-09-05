//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"
#import "ECCodeUnit.h"
#import "ECHashing.h"

@interface ECCodeCursor ()
{
    @private
    NSUInteger hash_;
}
@property (nonatomic, strong) ECCodeUnit *codeUnit;
@end

@implementation ECCodeCursor

@synthesize codeUnit = codeUnit_;
@synthesize language = language_;
@synthesize kind = kind_;
@synthesize spelling = spelling_;
@synthesize file = file_;
@synthesize offset = offset_;
@synthesize extent = extent_;
@synthesize unifiedSymbolResolution = unifiedSymbolResolution_;


- (id)initWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    self = [super init];
    if (!self)
        return nil;
    language_ = [language copy];
    kind_ = kind;
    spelling_ = [spelling copy];
    file_ = [file copy];
    offset_ = offset;
    extent_ = extent;
    unifiedSymbolResolution_ = [unifiedSymbolResolution copy];
    return self;
}

+ (id)cursorWithLanguage:(NSString *)language kind:(ECCodeCursorKind)kind spelling:(NSString *)spelling file:(NSString *)file offset:(NSUInteger)offset extent:(NSRange)extent unifiedSymbolResolution:(NSString *)unifiedSymbolResolution
{
    id cursor = [self alloc];
    cursor = [cursor initWithLanguage:language kind:kind spelling:spelling file:file offset:offset extent:extent unifiedSymbolResolution:unifiedSymbolResolution];
    return cursor;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)hash
{
    return hash_;
}

- (NSUInteger)computeHash
{
    const NSUInteger propertyCount = 8;
    NSUInteger propertyHashes[8] = { [language_ hash], kind_, [spelling_ hash], [file_ hash], offset_, extent_.location, extent_.length, [unifiedSymbolResolution_ hash]};
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
    if (spelling_ || otherCursor.spelling)
        if (![otherCursor.spelling isEqual:spelling_])
            return NO;
    if (file_ || otherCursor.file)
        if (![otherCursor.file isEqual:file_])
            return NO;
    if (unifiedSymbolResolution_ || otherCursor.unifiedSymbolResolution)
        if (![otherCursor.unifiedSymbolResolution isEqual:unifiedSymbolResolution_])
            return NO;
    return YES;
}

@end
