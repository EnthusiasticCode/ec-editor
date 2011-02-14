//
//  ECDiagnostic.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDiagnostic.h"


@implementation ECDiagnostic

@synthesize severity = _severity;
@synthesize location = _location;
@synthesize spelling = _spelling;
@synthesize category = _category;
@synthesize sourceRanges = _sourceRanges;
@synthesize fixIts = _fixIts;

- (void)dealloc
{
    [_location release];
    [_spelling release];
    [_category release];
    [_sourceRanges release];
    [_fixIts release];
    [super dealloc];
}

- (id)initWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts
{
    self = [super init];
    if (self)
    {
        _severity = severity;
        _location = [location retain];
        _spelling = [spelling copy];
        _category = [category copy];
        _sourceRanges = [sourceRanges copy];
        _fixIts = [fixIts copy];
    }
    return self;
}

+ (id)diagnosticWithSeverity:(ECDiagnosticSeverity)severity location:(ECSourceLocation *)location spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts
{
    id diagnostic = [self alloc];
    diagnostic = [diagnostic initWithSeverity:severity location:location spelling:spelling category:category sourceRanges:sourceRanges fixIts:fixIts];
    return [diagnostic autorelease];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Diagnostic at %@ : %@", self.location, self.spelling];
}

@end
