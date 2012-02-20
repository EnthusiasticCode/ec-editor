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
static NSString * const _changeTypeReplacement = @"CodeFileChangeTypeReplacement";
static NSString * const _changeTypeAttributeAdd = @"CodeFileChangeTypeAttributeAdd";
static NSString * const _changeTypeAttributeRemove = @"CodeFileChangeTypeAttributeRemove";
static NSString * const _changeRangeKey = @"CodeFileChangeRangeKey";
static NSString * const _changeStringKey = @"CodeFileChangeStringKey";
static NSString * const _changeAttributesKey= @"CodeFileChangeAttributesKey";
static NSString * const _changeAttributeNamesKey = @"CodeFileChangeAttributeNamesKey";

@interface CodeFile ()
{
    NSMutableAttributedString *_contents;
    CodeFileGeneration _contentsGeneration;
    OSSpinLock _contentsLock;
    WeakArray *_presenters;
    OSSpinLock _presentersLock;
    NSOperationQueue *_parserQueue;
    NSMutableArray *_pendingChanges;
    OSSpinLock _pendingChangesLock;
    BOOL _hasPendingChanges;
    NSUInteger _pendingGenerationOffset;
    NSArray *_symbolList;
}
@property (nonatomic, strong) TMUnit *codeUnit;
- (id)_initWithFileURL:(NSURL *)url;
- (void)_markPlaceholderWithName:(NSString *)name inAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range;
// Private content methods. All the following methods have to be called within a pending changes lock.
- (void)_setHasPendingChanges;
- (void)_processPendingChanges;
- (BOOL)_applyReplaceChangeWithRange:(NSRange)range string:(NSString *)string generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (BOOL)_applyAttributeAddChangeWithRange:(NSRange)range attributes:(NSDictionary *)attributes generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
- (BOOL)_applyAttributeRemoveChangeWithRange:(NSRange)range attributeNames:(NSArray *)attributeNames generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration;
@end

@interface CodeFileSymbol ()

@property (nonatomic, readwrite) BOOL separator;
- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range;

@end

#pragma mark - Implementations

@implementation CodeFile

@synthesize codeUnit = _codeUnit;
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
    _parserQueue = [[NSOperationQueue alloc] init];
    _parserQueue.maxConcurrentOperationCount = 1;
    _pendingChanges = [[NSMutableArray alloc] init];
    _pendingChangesLock = OS_SPINLOCK_INIT;
    _hasPendingChanges = NO;
    return self;
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [super openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            __weak CodeFile *weakSelf = self;
            [_parserQueue addOperationWithBlock:^{
                TMUnit *codeUnit = [[[TMIndex alloc] init] codeUnitForCodeFile:weakSelf rootScopeIdentifier:nil];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    weakSelf.codeUnit = codeUnit;
                }];
            }];
        }
        completionHandler(success);
    }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    [super closeWithCompletionHandler:^(BOOL success) {
        ECASSERT(success);
        [_parserQueue cancelAllOperations];
        self.codeUnit = nil;
        completionHandler(success);
    }];
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
    NSMutableAttributedString *contentsString = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    [contentsString addAttributes:self.theme.commonAttributes range:NSMakeRange(0, [contentsString length])];
    OSSpinLockLock(&_contentsLock);
    _contents = contentsString;
    ++_contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    return YES;
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(TextRenderer *)sender
{
    return [self length];
}

- (NSAttributedString *)textRenderer:(TextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
#warning TODO this needs to be moved to TMUnit, but I don't want to put the whole placeholder rendering logic inside TMUnit, do something about it
    NSMutableAttributedString *attributedString = [[self attributedStringInRange:stringRange] mutableCopy];
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

#define CONTENT_GETTER_WRAPPER(parameter, value) \
do\
{\
ECASSERT(parameter);\
OSSpinLockLock(&_contentsLock);\
if (expectedGeneration && *expectedGeneration != _contentsGeneration)\
{\
OSSpinLockUnlock(&_contentsLock);\
return NO;\
}\
*parameter = value;\
if (generation)\
*generation = _contentsGeneration;\
OSSpinLockUnlock(&_contentsLock);\
return YES;\
}\
while (0)

- (NSUInteger)length
{
    return [self lengthWithGeneration:NULL];
}

- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation
{
    NSUInteger length;
    [self length:&length withGeneration:generation expectedGeneration:NULL];
    return length;
}

- (BOOL)length:(NSUInteger *)length withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(length, [_contents length]);
}

- (NSString *)string
{
    return [self stringWithGeneration:NULL];
}

- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation
{
    NSString *string;
    [self string:&string withGeneration:generation expectedGeneration:NULL];
    return string;
}

- (BOOL)string:(NSString **)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(string, [_contents string]);
}

- (NSString *)stringInRange:(NSRange)range
{
    return [self stringInRange:range withGeneration:NULL];
}

- (NSString *)stringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSString *string;
    [self string:&string inRange:range withGeneration:generation expectedGeneration:NULL];
    return string;
}

- (BOOL)string:(NSString **)string inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(string, [[_contents string] substringWithRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    return [self lineRangeForRange:range withGeneration:NULL];
}

- (NSRange)lineRangeForRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSRange lineRange;
    [self lineRange:&lineRange forRange:range withGeneration:generation expectedGeneration:NULL];
    return lineRange;
}

- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(lineRange, [[_contents string] lineRangeForRange:range]);
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString
{
    return [self attributedStringWithGeneration:NULL];
}

- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation
{
    NSAttributedString *attributedString;
    [self attributedString:&attributedString withGeneration:generation expectedGeneration:NULL];
    return attributedString;
}

- (BOOL)attributedString:(NSAttributedString **)attributedString withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attributedString, [_contents copy]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    return [self attributedStringInRange:range withGeneration:NULL];
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation
{
    NSAttributedString *attributedString;
    [self attributedString:&attributedString inRange:range withGeneration:generation expectedGeneration:NULL];
    return attributedString;
}

- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attributedString, [_contents attributedSubstringFromRange:range]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range
{
    return [self attribute:attrName atIndex:location longestEffectiveRange:range withGeneration:NULL];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation
{
    id attribute;
    [self attribute:&attrName withName:attrName atIndex:index longestEffectiveRange:effectiveRange withGeneration:generation expectedGeneration:NULL];
    return attribute;
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attribute, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
    return [self attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit withGeneration:NULL];
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation
{
    id attribute;
    [self attribute:&attribute withName:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit withGeneration:generation expectedGeneration:NULL];
    return attribute;
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    CONTENT_GETTER_WRAPPER(attribute, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    [self replaceCharactersInRange:range withString:string withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)replaceCharactersInRange:(NSRange)range withString:(NSString *)string withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return YES;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return YES;
    if ([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue])
    {
        OSSpinLockLock(&_pendingChangesLock);
        [self _processPendingChanges];
        BOOL success = [self _applyReplaceChangeWithRange:range string:string generation:generation expectedGeneration:expectedGeneration];
        OSSpinLockUnlock(&_pendingChangesLock);
        return success;
    }
    else
    {
        NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, string, _changeStringKey, _changeTypeReplacement, _changeTypeKey, nil];
        OSSpinLockLock(&_pendingChangesLock);
        OSSpinLockLock(&_contentsLock);
        if (expectedGeneration && *expectedGeneration != _contentsGeneration + _pendingGenerationOffset)
        {
            OSSpinLockUnlock(&_contentsLock);
            OSSpinLockUnlock(&_pendingChangesLock);
            return NO;
        }
        ++_pendingGenerationOffset;
        if (generation)
            *generation = _contentsGeneration + _pendingGenerationOffset;
        OSSpinLockUnlock(&_contentsLock);
        [_pendingChanges addObject:change];
        [self _setHasPendingChanges];
        OSSpinLockUnlock(&_pendingChangesLock);
    }
    return YES;
}

#pragma mark - Attributed string content writing methods

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    [self addAttributes:attributes range:range withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    if (![attributes count] || !range.length)
        return YES;
    if ([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue])
    {
        OSSpinLockLock(&_pendingChangesLock);
        [self _processPendingChanges];
        BOOL success = [self _applyAttributeAddChangeWithRange:range attributes:attributes generation:generation expectedGeneration:expectedGeneration];
        OSSpinLockUnlock(&_pendingChangesLock);
        return success;
    }
    else
    {
        NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil];
        OSSpinLockLock(&_pendingChangesLock);
        OSSpinLockLock(&_contentsLock);
        if (expectedGeneration && *expectedGeneration != _contentsGeneration + _pendingGenerationOffset)
        {
            OSSpinLockUnlock(&_contentsLock);
            OSSpinLockUnlock(&_pendingChangesLock);
            return NO;
        }
        if (generation)
            *generation = _contentsGeneration + _pendingGenerationOffset;
        OSSpinLockUnlock(&_contentsLock);
        [_pendingChanges addObject:change];
        [self _setHasPendingChanges];
        OSSpinLockUnlock(&_pendingChangesLock);
    }
    return YES;
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    [self removeAttributes:attributeNames range:range withGeneration:NULL expectedGeneration:NULL];
}

- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range withGeneration:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (![attributeNames count] || !range.length)
        return YES;
    if ([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue])
    {
        OSSpinLockLock(&_pendingChangesLock);
        [self _processPendingChanges];
        BOOL success = [self _applyAttributeRemoveChangeWithRange:range attributeNames:attributeNames generation:generation expectedGeneration:expectedGeneration];
        OSSpinLockUnlock(&_pendingChangesLock);
        return success;
    }
    else
    {
        NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil];
        OSSpinLockLock(&_pendingChangesLock);
        OSSpinLockLock(&_contentsLock);
        if (expectedGeneration && *expectedGeneration != _contentsGeneration + _pendingGenerationOffset)
        {
            OSSpinLockUnlock(&_contentsLock);
            OSSpinLockUnlock(&_pendingChangesLock);
            return NO;
        }
        if (generation)
            *generation = _contentsGeneration + _pendingGenerationOffset;
        OSSpinLockUnlock(&_contentsLock);
        [_pendingChanges addObject:change];
        [self _setHasPendingChanges];
        OSSpinLockUnlock(&_pendingChangesLock);
    }
    return YES;
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
#warning TODO this loops forever if another thread is adding changes faster than we process them, maybe put a timeout and leave the remaining changes for the next batch?
    for (;;)
    {
        if (![_pendingChanges count])
        {
            _hasPendingChanges = NO;
            return;
        }
        NSDictionary *nextChange = [_pendingChanges objectAtIndex:0];
        [_pendingChanges removeObjectAtIndex:0];
        id changeType = [nextChange objectForKey:_changeTypeKey];
        ECASSERT(changeType && (changeType == _changeTypeReplacement || changeType == _changeTypeAttributeAdd || changeType == _changeTypeAttributeRemove));
        if (changeType == _changeTypeReplacement)
            [self _applyReplaceChangeWithRange:[[nextChange objectForKey:_changeRangeKey] rangeValue] string:[nextChange objectForKey:_changeStringKey] generation:NULL expectedGeneration:NULL];
        else if (changeType == _changeTypeAttributeAdd)
            [self _applyAttributeAddChangeWithRange:[[nextChange objectForKey:_changeRangeKey] rangeValue] attributes:[nextChange objectForKey:_changeAttributesKey] generation:NULL expectedGeneration:NULL];
        else if (changeType == _changeTypeAttributeRemove)
            [self _applyAttributeRemoveChangeWithRange:[[nextChange objectForKey:_changeRangeKey] rangeValue] attributeNames:[nextChange objectForKey:_changeAttributeNamesKey] generation:NULL expectedGeneration:NULL];
    }
}

- (BOOL)_applyReplaceChangeWithRange:(NSRange)range string:(NSString *)string generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:self.theme.commonAttributes];
    OSSpinLockLock(&_contentsLock);
    if (expectedGeneration && *expectedGeneration != _contentsGeneration)
    {
        OSSpinLockUnlock(&_contentsLock);
        return NO;
    }
    if ([string length])
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    else
        [_contents deleteCharactersInRange:range];
    ++_contentsGeneration;
    if (generation)
        *generation = _contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    OSSpinLockUnlock(&_pendingChangesLock);
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)])
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    OSSpinLockLock(&_pendingChangesLock);
    return YES;
}

- (BOOL)_applyAttributeAddChangeWithRange:(NSRange)range attributes:(NSDictionary *)attributes generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    OSSpinLockLock(&_contentsLock);
    if (expectedGeneration && *expectedGeneration != _contentsGeneration)
    {
        OSSpinLockUnlock(&_contentsLock);
        return NO;
    }
    [_contents addAttributes:attributes range:range];
    if (generation)
        *generation = _contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    OSSpinLockUnlock(&_pendingChangesLock);
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didAddAttributes:range:)])
            [presenter codeFile:self didAddAttributes:attributes range:range];
    OSSpinLockLock(&_pendingChangesLock);
    return YES;
}

- (BOOL)_applyAttributeRemoveChangeWithRange:(NSRange)range attributeNames:(NSArray *)attributeNames generation:(CodeFileGeneration *)generation expectedGeneration:(CodeFileGeneration *)expectedGeneration
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    OSSpinLockLock(&_contentsLock);
    if (expectedGeneration && *expectedGeneration != _contentsGeneration)
    {
        OSSpinLockUnlock(&_contentsLock);
        return NO;
    }
    for (NSString *attributeName in attributeNames)
        [_contents removeAttribute:attributeName range:range];
    if (generation)
        *generation = _contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    OSSpinLockUnlock(&_pendingChangesLock);
    for (id<CodeFilePresenter> presenter in [self presenters])
        if ([presenter respondsToSelector:@selector(codeFile:didRemoveAttributes:range:)])
            [presenter codeFile:self didRemoveAttributes:attributeNames range:range];
    OSSpinLockLock(&_pendingChangesLock);
    return YES;
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

- (NSArray *)symbolList
{
#warning TODO on long files if symbol list is opened before full parsing, the list is empty. add wait message
    if (!_symbolList)
    {
        NSMutableArray *symbols = [NSMutableArray new];
        [self.codeUnit visitScopesWithBlock:^TMUnitVisitResult(TMScope *scope, NSRange range) {
            if ([[TMPreference preferenceValueForKey:TMPreferenceShowInSymbolListKey scope:scope] boolValue])
            {
                // Transform
                NSString *(^transformation)(NSString *) = ((NSString *(^)(NSString *))[TMPreference preferenceValueForKey:TMPreferenceSymbolTransformationKey scope:scope]);
                NSString *symbol = transformation ? transformation([self stringInRange:range]) : [self stringInRange:range];
                // Generate
                CodeFileSymbol *s = [[CodeFileSymbol alloc] initWithTitle:symbol icon:[TMPreference preferenceValueForKey:TMPreferenceSymbolIconKey scope:scope] range:range];
                s.separator = [[TMPreference preferenceValueForKey:TMPreferenceSymbolIsSeparatorKey scope:scope] boolValue];
                [symbols addObject:s];
                return TMUnitVisitResultContinue;
            }
            return TMUnitVisitResultRecurse;
        }];
        _symbolList = symbols;
    }
    return _symbolList;
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

@implementation CodeFileSymbol

@synthesize title, icon, range, indentation, separator;

- (id)initWithTitle:(NSString *)_title icon:(UIImage *)_icon range:(NSRange)_range
{
    self = [super init];
    if (!self)
        return nil;
    // Get indentation level and modify title
    NSUInteger titleLength = [_title length];
    for (; indentation < titleLength; ++indentation)
    {
        if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[_title characterAtIndex:indentation]])
            break;
    }
    title = indentation ? [_title substringFromIndex:indentation] : _title;
    icon = _icon;
    range = _range;
    return self;
}

@end
