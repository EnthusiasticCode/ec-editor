//
//  ECCodeDiagnostic.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeDiagnostic.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeDiagnostic ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeDiagnostic

@synthesize severity = _severity;
@synthesize fileURL = _fileURL;
@synthesize offset = _offset;
@synthesize spelling = _spelling;
@synthesize category = _category;
@synthesize sourceRanges = _sourceRanges;
@synthesize fixIts = _fixIts;

- (void)dealloc
{
    [_fileURL release];
    [_spelling release];
    [_category release];
    [_sourceRanges release];
    [_fixIts release];
    [super dealloc];
}

- (id)initWithSeverity:(ECCodeDiagnosticSeverity)severity fileURL:(NSURL *)fileURL offset:(NSUInteger)offset spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts
{
    self = [super init];
    if (self)
    {
        _severity = severity;
        _fileURL = [fileURL copy];
        _offset = offset;
        _spelling = [spelling copy];
        _category = [category copy];
        _sourceRanges = [sourceRanges copy];
        _fixIts = [fixIts copy];
        _hash = [self computeHash];
    }
    return self;
}

+ (id)diagnosticWithSeverity:(ECCodeDiagnosticSeverity)severity fileURL:(NSURL *)fileURL offset:(NSUInteger)offset spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts
{
    id diagnostic = [self alloc];
    diagnostic = [diagnostic initWithSeverity:severity fileURL:fileURL offset:offset spelling:spelling category:category sourceRanges:sourceRanges fixIts:fixIts];
    return [diagnostic autorelease];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Diagnostic at %@;%d : %@", self.fileURL, self.offset, self.spelling];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSUInteger)hash
{
    return _hash;
}

- (NSUInteger)computeHash
{
    const NSUInteger propertyCount = 7;
    NSUInteger propertyHashes[7] = { _severity, [_fileURL hash], _offset, [_spelling hash], [_category hash], [_sourceRanges hash], [_fixIts hash]};
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeDiagnostic *otherDiagnostic = other;
    if (!otherDiagnostic.offset == _offset)
        return NO;
    if (!otherDiagnostic.severity == _severity)
        return NO;
    if (_fileURL || otherDiagnostic.fileURL)
        if (![otherDiagnostic.fileURL isEqual:_fileURL])
            return NO;
    if (_spelling || otherDiagnostic.spelling)
        if (![otherDiagnostic.spelling isEqual:_spelling])
            return NO;
    return YES;
}

@end
