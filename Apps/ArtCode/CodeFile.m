//
//  CodeFile.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFile+Generation.h"
#import "TMTheme.h"
#import "WeakArray.h"
#import <libkern/OSAtomic.h>

static NSString * const _changeTypeKey = @"CodeFileChangeTypeKey";
static NSString * const _changeTypeAttributeAdd = @"CodeFileChangeTypeAttributeAdd";
static NSString * const _changeTypeAttributeRemove = @"CodeFileChangeTypeAttributeRemove";
static NSString * const _changeTypeAttributeSet = @"CodeFileChangeTypeAttributeSet";
static NSString * const _changeTypeAttributeRemoveAll = @"CodeFileChangeTypeAttributeRemoveAll";
static NSString * const _changeRangeKey = @"CodeFileChangeRangeKey";
static NSString * const _changeAttributesKey= @"CodeFileChangeAttributesKey";
static NSString * const _changeAttributeNamesKey = @"CodeFileChangeAttributeNamesKey";


@interface CodeFile ()

- (id)_initWithFileURL:(NSURL *)url;

// Private content methods. All the following methods have to be called within a pending changes lock.
- (void)_setHasPendingChanges;
- (void)_processPendingChanges;

@end

#pragma mark -
@implementation CodeFile {
    NSMutableAttributedString *_contents;
    CodeFileGeneration _contentsGeneration;
    OSSpinLock _contentsLock;
    WeakArray *_presenters;
    OSSpinLock _presentersLock;
    NSMutableArray *_pendingChanges;
    OSSpinLock _pendingChangesLock;
    BOOL _hasPendingChanges;
    NSUInteger _pendingGenerationOffset;
}

@synthesize theme = _theme;

#pragma mark - UIDocument

- (id)initWithFileURL:(NSURL *)url {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    self = [super initWithFileURL:url];
    if (!self) {
        return nil;
    }
    _contents = [[NSMutableAttributedString alloc] init];
    _contentsLock = OS_SPINLOCK_INIT;
    _presenters = [[WeakArray alloc] init];
    _presentersLock = OS_SPINLOCK_INIT;
    _pendingChanges = [[NSMutableArray alloc] init];
    _pendingChangesLock = OS_SPINLOCK_INIT;
    _hasPendingChanges = NO;
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    OSSpinLockLock(&_contentsLock);
    NSData *contentsData = [[_contents string] dataUsingEncoding:NSUTF8StringEncoding];
    OSSpinLockUnlock(&_contentsLock);
    return contentsData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    [self replaceCharactersInRange:NSMakeRange(0, [self length]) withString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    return YES;
}

#pragma mark - Public methods

- (TMTheme *)theme {
    if (!_theme) {
        _theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
    }
    return _theme;
}

- (void)addPresenter:(id<CodeFilePresenter>)presenter {
    ECASSERT(![_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters addObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (void)removePresenter:(id<CodeFilePresenter>)presenter {
    ECASSERT([_presenters containsObject:presenter]);
    OSSpinLockLock(&_presentersLock);
    [_presenters removeObject:presenter];
    OSSpinLockUnlock(&_presentersLock);
}

- (NSArray *)presenters {
    NSArray *presenters;
    OSSpinLockLock(&_presentersLock);
    presenters = [_presenters copy];
    OSSpinLockUnlock(&_presentersLock);
    return presenters;
}

- (CodeFileGeneration)currentGeneration {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return _contentsGeneration;
}

#pragma mark - String content reading methods

#define CONTENT_GETTER(type, value) \
do {\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
type __value;\
OSSpinLockLock(&_contentsLock);\
__value = value;\
OSSpinLockUnlock(&_contentsLock);\
return __value;\
}\
while (0)

#define CONTENT_GETTER_GENERATION(type, value) \
do {\
type __value;\
OSSpinLockLock(&_contentsLock);\
__value = value;\
if (generation) {\
*generation = _contentsGeneration;\
}\
OSSpinLockUnlock(&_contentsLock);\
return __value;\
}\
while (0)

#define CONTENT_GETTER_EXPECTED_GENERATION(parameter, value) \
do {\
ECASSERT(parameter);\
OSSpinLockLock(&_contentsLock);\
if (expectedGeneration != _contentsGeneration) {\
OSSpinLockUnlock(&_contentsLock);\
return NO;\
}\
*parameter = value;\
OSSpinLockUnlock(&_contentsLock);\
return YES;\
}\
while (0)

- (NSUInteger)length {
    CONTENT_GETTER(NSUInteger, [_contents length]);
}

- (NSUInteger)lengthWithGeneration:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSUInteger, [_contents length]);
}

- (BOOL)length:(NSUInteger *)length expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(length, [_contents length]);
}

- (NSString *)string {
    CONTENT_GETTER(NSString *, [_contents string]);
}

- (NSString *)stringWithGeneration:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSString *, [_contents string]);
}

- (BOOL)string:(NSString **)string expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(string, [_contents string]);
}

- (NSString *)stringInRange:(NSRange)range {
    CONTENT_GETTER(NSString *, [[_contents string] substringWithRange:range]);
}

- (NSString *)stringInRange:(NSRange)range generation:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSString *, [[_contents string] substringWithRange:range]);
}

- (BOOL)string:(NSString **)string inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(string, [[_contents string] substringWithRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range {
    CONTENT_GETTER(NSRange, [[_contents string] lineRangeForRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range generation:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSRange, [[_contents string] lineRangeForRange:range]);
}

- (BOOL)lineRange:(NSRangePointer)lineRange forRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(lineRange, [[_contents string] lineRangeForRange:range]);
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString {
    CONTENT_GETTER(NSAttributedString *, [_contents copy]);
}

- (NSAttributedString *)attributedStringWithGeneration:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSAttributedString *, [_contents copy]);
}

- (BOOL)attributedString:(NSAttributedString **)attributedString expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(attributedString, [_contents copy]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range {
    CONTENT_GETTER(NSAttributedString *, [_contents attributedSubstringFromRange:range]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range generation:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(NSAttributedString *, [_contents attributedSubstringFromRange:range]);
}

- (BOOL)attributedString:(NSAttributedString **)attributedString inRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(attributedString, [_contents attributedSubstringFromRange:range]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange {
    CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange generation:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(id, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(attribute, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit {
    CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit generation:(CodeFileGeneration *)generation {
    CONTENT_GETTER_GENERATION(id, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

- (BOOL)attribute:(id *)attribute withName:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_GETTER_EXPECTED_GENERATION(attribute, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length]) {
        return;
    }
    
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]]) {
        return;
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:self.theme.commonAttributes];
    OSSpinLockLock(&_pendingChangesLock);
    [self _processPendingChanges];
    
    OSSpinLockLock(&_contentsLock);
    if ([string length]) {
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    } else {
        [_contents deleteCharactersInRange:range];
    }
    ++_contentsGeneration;
    OSSpinLockUnlock(&_contentsLock);
    
    OSSpinLockUnlock(&_pendingChangesLock);
    [self updateChangeCount:UIDocumentChangeDone];
    for (id<CodeFilePresenter>presenter in [self presenters]) {
        if ([presenter respondsToSelector:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)]) {
            [presenter codeFile:self didReplaceCharactersInRange:range withAttributedString:attributedString];
        }
    }
}

#pragma mark - Attributed string content writing methods

#define CONTENT_MODIFIER(...) \
do {\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
if (!range.length) {\
return;\
}\
ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);\
OSSpinLockLock(&_pendingChangesLock);\
[_pendingChanges addObject:__VA_ARGS__];\
[self _processPendingChanges];\
OSSpinLockUnlock(&_pendingChangesLock);\
}\
while (0)

#define CONTENT_MODIFIER_EXPECTED_GENERATION(...) \
do {\
ECASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);\
if (!range.length) {\
return YES;\
}\
NSDictionary *change = __VA_ARGS__;\
OSSpinLockLock(&_pendingChangesLock);\
OSSpinLockLock(&_contentsLock);\
if (expectedGeneration != _contentsGeneration + _pendingGenerationOffset) {\
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

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range {
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil]);
}

- (BOOL)addAttributes:(NSDictionary *)attributes range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil]);
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range {
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil]);
}

- (BOOL)removeAttributes:(NSArray *)attributeNames range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil]);
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeSet, _changeTypeKey, nil]);
}

- (BOOL)setAttributes:(NSDictionary *)attributes range:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeSet, _changeTypeKey, nil]);
}

- (void)removeAllAttributesInRange:(NSRange)range {
    CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemoveAll, _changeTypeKey, nil]);
}

- (BOOL)removeAllAttributesInRange:(NSRange)range expectedGeneration:(CodeFileGeneration)expectedGeneration {
    CONTENT_MODIFIER_EXPECTED_GENERATION([NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemoveAll, _changeTypeKey, nil]);
}

#pragma mark - Find and replace functionality
#warning TODO these need support for transactions, pending changes and be better integrated with the multithreaded content management system, but they have to be replaced by onigregexp anyway so I'm leaving them broken for the time being

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp numberOfMatchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [regexp matchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    return [result.regularExpression replacementStringForResult:result inString:[self string] offset:offset template:replacementTemplate];
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset {
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(match && replacementTemplate);
    
    NSRange replacementRange = match.range;
    NSString *replacementString =  [self replacementStringForResult:match offset:offset template:replacementTemplate];
    
    replacementRange.location += offset;
    [self replaceCharactersInRange:replacementRange withString:replacementString];
    replacementRange.length = replacementString.length;
    return replacementRange;
}

#pragma mark - Private Methods

- (void)_setHasPendingChanges {
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
    
    if (!_hasPendingChanges) {
        return;
    }
    
    for (;;) {
        if (![_pendingChanges count]) {
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
        if (changeType == _changeTypeAttributeAdd) {
            ECASSERT([[nextChange objectForKey:_changeAttributesKey] count]);
            [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
        } else if (changeType == _changeTypeAttributeRemove) {
            ECASSERT([[nextChange objectForKey:_changeAttributeNamesKey] count]);
            for (NSString *attributeName in [nextChange objectForKey:_changeAttributeNamesKey])
                [_contents removeAttribute:attributeName range:range];
        } else if (changeType == _changeTypeAttributeSet) {
            ECASSERT([[nextChange objectForKey:_changeAttributesKey] count]);
            [_contents setAttributes:self.theme.commonAttributes range:range];
            [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
        } else if (changeType == _changeTypeAttributeRemoveAll) {
            [_contents setAttributes:self.theme.commonAttributes range:range];
        }
        OSSpinLockUnlock(&_contentsLock);

        for (id<CodeFilePresenter> presenter in [self presenters]) {
            if ([presenter respondsToSelector:@selector(codeFile:didChangeAttributesInRange:)]) {
                [presenter codeFile:self didChangeAttributesInRange:range];
            }
        }
        
        OSSpinLockLock(&_pendingChangesLock);
    }
}

@end
