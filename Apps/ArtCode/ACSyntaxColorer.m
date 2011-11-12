//
//  ACSyntaxColorer.m
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSyntaxColorer.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>
#import <CoreText/CoreText.h>

@interface ACSyntaxColorer ()
{
    ECAttributedUTF8FileBuffer *_fileBuffer;
    ECCodeUnit *_codeUnit;
}
@end

@implementation ACSyntaxColorer

@synthesize theme = _theme;
@synthesize defaultTextAttributes = _defaultTextAttributes;

- (id)initWithFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _fileBuffer = fileBuffer;
    ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
    _codeUnit = [codeIndex codeUnitForFile:[_fileBuffer fileURL] scope:nil];
    return self;
}

- (ECAttributedUTF8FileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (ECCodeUnit *)codeUnit
{
    return _codeUnit;
}

- (void)applySyntaxColoringToRange:(NSRange)range
{
    [_fileBuffer setAttributes:self.defaultTextAttributes range:range];
    for (id<ECCodeToken>token in [_codeUnit annotatedTokensInRange:range])
    {
        NSRange relativeRange = NSIntersectionRange([token range], range);
        if (!relativeRange.length)
            continue;
        else
            relativeRange.location -= range.location;
        [_fileBuffer addAttributes:[self.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:relativeRange];
    }
}

@end
