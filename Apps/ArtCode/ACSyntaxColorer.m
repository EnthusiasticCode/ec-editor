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
    id _fileBufferObserver;
    BOOL _needsToReapplySyntaxColoring;
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
    _codeUnit = [codeIndex codeUnitForFileBuffer:fileBuffer scope:nil];
    _needsToReapplySyntaxColoring = YES;
    _fileBufferObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ECFileBufferWillReplaceCharactersNotificationName object:fileBuffer queue:nil usingBlock:^(NSNotification *note) {
        _needsToReapplySyntaxColoring = YES;
    }];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_fileBufferObserver];
}

- (ECAttributedUTF8FileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (ECCodeUnit *)codeUnit
{
    return _codeUnit;
}

- (void)applySyntaxColoring
{
    if (!_needsToReapplySyntaxColoring)
        return;
    NSRange range = NSMakeRange(0, [_fileBuffer length]);
    [_fileBuffer setAttributes:self.defaultTextAttributes range:range];
    for (id<ECCodeToken>token in [_codeUnit annotatedTokensInRange:range])
        [_fileBuffer addAttributes:[self.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:[token range]];
    _needsToReapplySyntaxColoring = NO;
}

@end
