//
//  CodeFile.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile+Generation.h"
#import "TMTheme.h"
#import "TMIndex.h"
#import "TMUnit.h"
#import "TMScope.h"
#import "TMPreference.h"
#import "WeakDictionary.h"
#import "WeakArray.h"
#import <libkern/OSAtomic.h>

static WeakDictionary *_codeFiles;

static NSString * const _changeTypeKey = @"CodeFileChangeTypeKey";
static NSString * const _changeTypeAttributeAdd = @"CodeFileChangeTypeAttributeAdd";
static NSString * const _changeTypeAttributeRemove = @"CodeFileChangeTypeAttributeRemove";
static NSString * const _changeTypeAttributeSet = @"CodeFileChangeTypeAttributeSet";
static NSString * const _changeTypeAttributeRemoveAll = @"CodeFileChangeTypeAttributeRemoveAll";
static NSString * const _changeRangeKey = @"CodeFileChangeRangeKey";
static NSString * const _changeAttributesKey= @"CodeFileChangeAttributesKey";
static NSString * const _changeAttributeNamesKey = @"CodeFileChangeAttributeNamesKey";

@interface CodeFile ()
{
    NSMutableAttributedString *_contents;
    CodeFileGeneration _contentsGeneration;
    OSSpinLock _contentsLock;
    WeakArray *_presenters;
    OSSpinLock _presentersLock;
    NSMutableArray *_pendingChanges;
    OSSpinLock _pendingChangesLock;
    BOOL _hasPendingChanges;
    NSUInteger _pendingGenerationOffset;
    NSArray *_symbolList;
}
- (id)_initWithFileURL:(NSURL *)url;
- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range;
// Private content methods. All the following methods have to be called within a pending changes lock.
- (void)_setHasPendingChanges;
- (void)_processPendingChanges;
@end

#pragma mark - Implementations

@implementation CodeFile

@synthesize theme = _theme;

+ (void)initialize
{
    if (self != [CodeFile class])
        return;
    _codeFiles = [[WeakDictionary alloc] init];
}

+ (void)codeFileWithFileURL:(NSURL *)fileURL completionHandler:(void (^)(CodeFile *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(fileURL);
    CodeFile *codeFile = [_codeFiles objectForKey:fileURL];
    if (codeFile)
        return completionHandler(codeFile);
    __block BOOL fileExists;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
        fileExists = [[[NSFileManager alloc] init] fileExistsAtPath:[newURL path]];
    }];
    codeFile = [[self alloc] _initWithFileURL:fileURL];
    [codeFile openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            [_codeFiles setObject:codeFile forKey:fileURL];
            completionHandler(codeFile);
        }
        else
        {
            completionHandler(nil);
        }
    }];
}

- (TMTheme *)theme
{
    if (!_theme)
        _theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    return _theme;
}

#pragma mark - UIDocument Methods

- (id)initWithFileURL:(NSURL *)url
{
    UNIMPLEMENTED();
}

- (id)_initWithFileURL:(NSURL *)url
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    self = [super initWithFileURL:url];
    if (!self)
        return nil;
    _contents = [[NSMutableAttributedString alloc] init];
    _contentsLock = OS_SPINLOCK_INIT;
    _presenters = [[WeakArray alloc] init];
    _presentersLock = OS_SPINLOCK_INIT;
    _pendingChanges = [[NSMutableArray alloc] init];
    _pendingChangesLock = OS_SPINLOCK_INIT;
    _hasPendingChanges = NO;
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    OSSpinLockLock(&_contentsLock);
    NSData *contentsData = [[_contents string] dataUsingEncoding:NSUTF8StringEncoding];
    OSSpinLockUnlock(&_contentsLock);
    return contentsData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    [self replaceCharactersInRange:NSMakeRange(0, [self length]) withString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(TextRenderer *)sender
{
    return [self lengthWithGeneration:NULL];
}

- (NSAttributedString *)textRenderer:(TextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
#warning TODO this needs to be moved to TMUnit, but I don't want to put the whole placeholder rendering logic inside TMUnit, do something about it
    NSMutableAttributedString *attributedString = [[self attributedStringInRange:stringRange generation:NULL] mutableCopy];
    static NSRegularExpression *placeholderRegExp = nil;
    if (!placeholderRegExp)
        placeholderRegExp = [NSRegularExpression regularExpressionWithPattern:@"<#(.+?)#>" options:0 error:NULL];
    // Add placeholders styles
    [placeholderRegExp enumerateMatchesInString:[attributedString string] options:0 range:NSMakeRange(0, [attributedString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [self _markPlaceholderWithName:[self stringInRange:[result rangeAtIndex:1]] inAttributedString:attributedString range:result.range];
    }];
    return attributedString;
}

- (NSDictionary *)defaultTextAttributedForTextRenderer:(TextRenderer *)sender
{
    return [self.theme commonAttributes];
}

- (void)codeView:(CodeView *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    [self replaceCharactersInRange:range withString:commitString];
}

- (id)codeView:(CodeView *)codeView attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange
{
    return [self attribute:attributeName atIndex:index longestEffectiveRange:effectiveRange];
}

#pragma mark - Public methods

- (void)addPresenter:(id<CodeFilePresenter>)presenter
{
    ECASSERT(![_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters addObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (void)removePresenter:(id<CodeFilePresenter>)presenter
{
    ECASSERT([_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters removeObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (NSArray *)presenters
{
    NSArray *presenters;
    OSSpinLockLock(&_presentersLock);
    presenters = [_presenters copy];
    OSSpinLockUnlock(&_presentersLock);
    return presenters;
}

#pragma mark - String content reading methods

- (CodeFileGeneration)currentGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return _contentsGeneration;
}

#define CONTENT_GETTER(type, value) \
do\
{\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
type __value;\
OSSpinLockLock(&_contentsLock);\
__value = value;\
OSSpinLockUnlock(&_contentsLock);\
return __value;\
}\
while (0)

#define CONTENT_GETTER_GENERATION(type, value) \
do\
{\
type __value;\
OSSpinLockLock(&_contentsLock);\
__value = value;\
if (generation)\
*generation = _contentsGeneration;\
OSSpinLockUnlock(&_contentsLock);\
return __value;\
}\
while (0)

#define CONTENT_GETTER_EXPECTED_GENERATION(parameter, value) \
do\
{\
ECASSERT(parameter);\
OSSpinLockLock(&_contentsLock);\
if (expectedGeneration != _contentsGeneration)\
{\
OSSpinLockUnlock(&_contentsLock);\
return NO;\
}\
*parameter = value;\
OSSpinLockUnlock(&_contentsLock);\
return YES;\
}\
while (0)

- (NSUInteger)length
{
    CONTENT_GETTER(NSUInteger, [_contents length]);
}

- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSUInteger, [_contents length]);
}

- (BOOL)length:(NSUInteger *)length expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(length, [_contents length]);
}

- (NSString *)string
{
    CONTENT_GETTER(NSString *, [_contents string]);
}

- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSString *, [_contents string]);
}

- (BOOL)string:(NSString **)string expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(string, [_contents string]);
}

- (NSString *)stringInRange:(NSRange)range
{
    CONTENT_GETTER(NSString *, [[_contents string] substringWithRange:range]);
}

- (NSString *)stringInRange:(NSRange)range generation:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSString *, [[_contents string] substringWithRange:range]);
}

- (BOOL)string:(NSString **)string inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(string, [[_contents string] substringWithRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    CONTENT_GETTER(NSRange, [[_contents string] lineRangeForRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range generation:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSRange, [[_contents string] lineRangeForRange:range]);
}

- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(lineRange, [[_contents string] lineRangeForRange:range]);
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString
{
    CONTENT_GETTER(NSAttributedString *, [_contents copy]);
}

- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSAttributedString *, [_contents copy]);
}

- (BOOL)attributedString:(NSAttributedString **)attributedString expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(attributedString, [_contents copy]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    CONTENT_GETTER(NSAttributedString *, [_contents attributedSubstringFromRange:range]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range generation:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(NSAttributedString *, [_contents attributedSubstringFromRange:range]);
}

- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(attributedString, [_contents attributedSubstringFromRange:range]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange
{
    CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange generation:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(id, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(attribute, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit
{
    CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit generation:(CodeFileGeneration *)generation
{
    CONTENT_GETTER_GENERATION(id, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_GETTER_EXPECTED_GENERATION(attribute, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return;
    OSSpinLockLock(&_pendingChangesLock);
    [self _processPendingChanges];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:self.theme.commonAttributes];
    OSSpinLockLock(&_contentsLock);
    if ([string length])
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    else
        [_contents deleteCharactersInRange:range];
    ++_contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    OSSpinLockUnlock(&_pendingChangesLock);
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
}

#pragma mark - Attributed string content writing methods

#define CONTENT_MODIFIER(...) \
do\
{\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
if (!range.length)\
return;\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
OSSpinLockLock(&_pendingChangesLock);\
[_pendingChanges addObject:__VA_ARGS__];\
[self _processPendingChanges];\
OSSpinLockUnlock(&_pendingChangesLock);\
}\
while (0)

#define CONTENT_MODIFIER_EXPECTED_GENERATION(...) \
do\
{\
ECASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);\
if (!range.length)\
return YES;\
NSDictionary *change = __VA_ARGS__;\
OSSpinLockLock(&_pendingChangesLock);\
OSSpinLockLock(&_contentsLock);\
if (expectedGeneration != _contentsGeneration + _pendingGenerationOffset)\
{\
    OSSpinLockUnlock(&_contentsLock);\
    OSSpinLockUnlock(&_pendingChangesLock);\
    return NO;\
}\
OSSpinLockUnlock(&_contentsLock);\
[_pendingChanges addObject:change];\
[self _setHasPendingChanges];\
OSSpinLockUnlock(&_pendingChangesLock);\
return YES;\
}\
while (0)

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil]);
}

- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil]);
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil]);
}

- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil]);
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeSet, _changeTypeKey, nil]);
}

- (BOOL)setAttributes:(NSDictionary *)attributes range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeSet, _changeTypeKey, nil]);
}

- (void)removeAllAttributesInRange:(NSRange)range
{
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemoveAll, _changeTypeKey, nil]);
}

- (BOOL)removeAllAttributesInRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration
{
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemoveAll, _changeTypeKey, nil]);
}

#pragma mark - Private content methods

- (void)_setHasPendingChanges
{
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    if (_hasPendingChanges)
        return;
    _hasPendingChanges = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        OSSpinLockLock(&_pendingChangesLock);
        [self _processPendingChanges];
        OSSpinLockUnlock(&_pendingChangesLock);
    }];
}

- (void)_processPendingChanges
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    if (!_hasPendingChanges)
        return;
    for (;;)
    {
        if (![_pendingChanges count])
        {
            _hasPendingChanges = NO;
            return;
        }
        NSDictionary *nextChange = [_pendingChanges objectAtIndex:0];
        [_pendingChanges removeObjectAtIndex:0];
        OSSpinLockUnlock(&_pendingChangesLock);
        id changeType = [nextChange objectForKey:_changeTypeKey];
        ECASSERT(changeType && (changeType == _changeTypeAttributeAdd || changeType == _changeTypeAttributeRemove || changeType == _changeTypeAttributeSet|| changeType == _changeTypeAttributeRemoveAll));
        ECASSERT([nextChange objectForKey:_changeRangeKey]);
        NSRange range = [[nextChange objectForKey:_changeRangeKey] rangeValue];
        OSSpinLockLock(&_contentsLock);
        if (changeType == _changeTypeAttributeAdd)
        {
            ECASSERT([[nextChange objectForKey:_changeAttributesKey] count]);
            [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
        }
        else if (changeType == _changeTypeAttributeRemove)
        {
            ECASSERT([[nextChange objectForKey:_changeAttributeNamesKey] count]);
            for (NSString *attributeName in [nextChange objectForKey:_changeAttributeNamesKey])
                [_contents removeAttribute:attributeName range:range];
        }
        else if (changeType == _changeTypeAttributeSet)
        {
            ECASSERT([[nextChange objectForKey:_changeAttributesKey] count]);
            [_contents setAttributes:self.theme.commonAttributes range:range];
            [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
        }
        else if (changeType == _changeTypeAttributeRemoveAll)
        {
            [_contents setAttributes:self.theme.commonAttributes range:range];
        }
        OSSpinLockUnlock(&_contentsLock);
        for (id<CodeFilePresenter> presenter in [self presenters])
            if ([presenter respondsToSelector:@selector(codeFile:didChangeAttributesInRange:)])
                [presenter codeFile:self didChangeAttributesInRange:range];
        OSSpinLockLock(&_pendingChangesLock);
    }
}

#pragma mark - Find and replace functionality
#warning TODO replace all these with methods based on OnigRegexp
#warning TODO these need support for generation and be better integrated with the multithreaded content management system, but they're going to be replaced by onigregexp anyway

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp numberOfMatchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp matchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [result.regularExpression replacementStringForResult:result inString:[self string] offset:offset template:replacementTemplate];
}

#warning TODO this doesn't handle pending changes because it's going to have to be replaced by onigregexp anyway
- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(match && replacementTemplate);
    
    NSRange replacementRange = match.range;
    NSString *replacementString =  [self replacementStringForResult:match offset:offset template:replacementTemplate];
    
    replacementRange.location += offset;
    [self replaceCharactersInRange:replacementRange withString:replacementString];
    replacementRange.length = replacementString.length;
    return replacementRange;
}

#pragma mark - Private methods

static CGFloat placeholderEndingsWidthCallback(void *refcon) {
    if (refcon)
    {
        CGFloat height = CTFontGetXHeight(refcon);
        return height / 2.0;
    }
    return 4.5;
}

static CTRunDelegateCallbacks placeholderEndingsRunCallbacks = {
    kCTRunDelegateVersion1,
    NULL,
    NULL,
    NULL,
    &placeholderEndingsWidthCallback
};

- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range
{
    ECASSERT(range.length > 4);
    
    static CGColorRef placeholderFillColor = NULL;
    if (!placeholderFillColor)
        placeholderFillColor = CGColorRetain([UIColor colorWithRed:234.0/255.0 green:240.0/255.0 blue:250.0/255.0 alpha:1].CGColor);
    
    static CGColorRef placeholderStrokeColor = NULL;
    if (!placeholderStrokeColor)
        placeholderStrokeColor = CGColorRetain([UIColor colorWithRed:197.0/255.0 green:216.0/255.0 blue:243.0/255.0 alpha:1].CGColor);
    
    static TextRendererRunBlock placeHolderBodyBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextAddRect(context, rect);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rect.origin.y);
        CGContextMoveToPoint(context, rect.origin.x, CGRectGetMaxY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static TextRendererRunBlock placeholderLeftBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rectMax.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rect.origin.x, rect.origin.y, rect.origin.x, rectMax.y, rectMax.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    static TextRendererRunBlock placeholderRightBlock = ^(CGContextRef context, CTRunRef run, CGRect rect, CGFloat baselineOffset) {
        rect.origin.y += 1;
        rect.size.height -= baselineOffset;
        CGPoint rectMax = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, placeholderFillColor);
        CGContextFillPath(context);
        //
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddCurveToPoint(context, rectMax.x, rect.origin.y, rectMax.x, rectMax.y, rect.origin.x, rectMax.y);
        CGContextSetStrokeColorWithColor(context, placeholderStrokeColor);
        CGContextStrokePath(context);
    };
    
    // placeholder body style
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:placeHolderBodyBlock, TextRendererRunUnderlayBlockAttributeName, [UIColor blackColor].CGColor, kCTForegroundColorAttributeName, nil] range:NSMakeRange(range.location + 2, range.length - 4)];
    
    // Opening and Closing style
    
    //
    CGFontRef font = (__bridge CGFontRef)[[TMTheme sharedAttributes] objectForKey:(__bridge id)kCTFontAttributeName];
    ECASSERT(font);
    CTRunDelegateRef delegateRef = CTRunDelegateCreate(&placeholderEndingsRunCallbacks, font);
    
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderLeftBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(range.location, 2)];
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)delegateRef, kCTRunDelegateAttributeName, placeholderRightBlock, TextRendererRunDrawBlockAttributeName, nil] range:NSMakeRange(NSMaxRange(range) - 2, 2)];
    
    CFRelease(delegateRef);
    
    // Placeholder behaviour
    [attributedString addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:name, CodeViewPlaceholderAttributeName, nil] range:range];
}

@end
