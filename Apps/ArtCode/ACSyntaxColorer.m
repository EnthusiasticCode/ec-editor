//
//  ACSyntaxColorer.m
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSyntaxColorer.h"
#import <ECFoundation/ECFileBuffer.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/TMTheme.h>
#import <ECUIKit/ECTextStyle.h>
#import <CoreText/CoreText.h>

@interface SyntaxColoringOperation : NSOperation
{
    ACSyntaxColorer *_syntaxColorer;
    NSRange _range;
}
- (id)initWithSyntaxColorer:(ACSyntaxColorer *)syntaxColorer range:(NSRange)range;
NSRange rangeRelativeToRange(NSRange range, NSRange referenceRange);
@end

@implementation SyntaxColoringOperation

- (id)initWithSyntaxColorer:(ACSyntaxColorer *)syntaxColorer range:(NSRange)range
{
    ECASSERT(syntaxColorer && NSMaxRange(range) <= [[syntaxColorer fileBuffer] length]);
    self = [super init];
    if (!self)
        return nil;
    _syntaxColorer = syntaxColorer;
    _range = range;
    return self;
}

- (void)main
{
    if (self.isCancelled)
        return;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[[_syntaxColorer fileBuffer] stringInRange:_range] attributes:_syntaxColorer.defaultTextAttributes];
    if (![string length])
        return;
    
    if (self.isCancelled)
        return;
    
    for (id<ECCodeToken>token in [[_syntaxColorer codeUnit] annotatedTokensInRange:_range])
    {
        if (self.isCancelled)
            return;
        [string addAttributes:[_syntaxColorer.theme attributesForScopeStack:[token scopeIdentifiersStack]] range:rangeRelativeToRange([token range], _range)];
        if (self.isCancelled)
            return;
    }
    
    if (self.isCancelled)
        return;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.isCancelled)
            return;
        [[_syntaxColorer fileBuffer] replaceCharactersInRange:_range withAttributedString:string];
    }];
}

NSRange rangeRelativeToRange(NSRange range, NSRange referenceRange)
{
    NSRange relativeRange = NSIntersectionRange(range, referenceRange);
    relativeRange.location -= referenceRange.location;
    return relativeRange;
}

@end

@interface ACSyntaxColorer ()
{
    ECFileBuffer *_fileBuffer;
    NSOperationQueue *_parserQueue;
    ECCodeUnit *_codeUnit;
}
@end

@implementation ACSyntaxColorer

@synthesize theme = _theme;
@synthesize defaultTextAttributes = _defaultTextAttributes;

- (id)initWithFileBuffer:(ECFileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _fileBuffer = fileBuffer;
    _parserQueue = [[NSOperationQueue alloc] init];
    _parserQueue.maxConcurrentOperationCount = 1;
    ECCodeIndex *codeIndex = [[ECCodeIndex alloc] init];
    __weak ACSyntaxColorer *this = self;
    [_parserQueue addOperationWithBlock:^{
        ECCodeUnit *codeUnit = [codeIndex codeUnitForFile:[this->_fileBuffer fileURL] scope:nil];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            this->_codeUnit = codeUnit;
        }];
    }];
    return self;
}

- (void)dealloc
{
    [_parserQueue cancelAllOperations];
}

- (ECFileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (ECCodeUnit *)codeUnit
{
    return _codeUnit;
}

- (void)applySyntaxColoringToRange:(NSRange)range
{
    [_parserQueue addOperation:[[SyntaxColoringOperation alloc] initWithSyntaxColorer:self range:range]];
}

@end
