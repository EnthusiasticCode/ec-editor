//
//  FileBuffer.m
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FileBuffer.h"
#import "WeakArray.h"
#import "ACProjectFile.h"
#import "ACProject.h"
#import <libkern/OSAtomic.h>

static NSString * const _changeTypeKey = @"CodeFileChangeTypeKey";
static NSString * const _changeTypeAttributeAdd = @"CodeFileChangeTypeAttributeAdd";
static NSString * const _changeTypeAttributeRemove = @"CodeFileChangeTypeAttributeRemove";
static NSString * const _changeTypeAttributeSet = @"CodeFileChangeTypeAttributeSet";
static NSString * const _changeTypeAttributeRemoveAll = @"CodeFileChangeTypeAttributeRemoveAll";
static NSString * const _changeRangeKey = @"CodeFileChangeRangeKey";
static NSString * const _changeAttributesKey= @"CodeFileChangeAttributesKey";
static NSString * const _changeAttributeNamesKey = @"CodeFileChangeAttributeNamesKey";


@interface FileBuffer ()

// Private content methods. All the following methods have to be called within a pending changes lock.
- (void)_setHasPendingChanges;
- (void)_processPendingChanges;

@end

#pragma mark -
@implementation FileBuffer {
  NSMutableAttributedString *_contents;
  OSSpinLock _contentsLock;
  WeakArray *_presenters;
  OSSpinLock _presentersLock;
  NSMutableArray *_pendingChanges;
  OSSpinLock _pendingChangesLock;
  BOOL _hasPendingChanges;
  NSUInteger _pendingGenerationOffset;
}

@synthesize defaultAttributes = _defaultAttributes;

#pragma mark - NSObject

- (id)init {
  self = [super init];
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

#pragma mark - Public methods

- (void)addPresenter:(id<FileBufferPresenter>)presenter {
  ASSERT(![_presenters containsObject:presenter]);
  OSSpinLockLock(&_presentersLock);
  [_presenters addObject:presenter];
  OSSpinLockUnlock(&_presentersLock);
}

- (void)removePresenter:(id<FileBufferPresenter>)presenter {
  ASSERT([_presenters containsObject:presenter]);
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

#pragma mark - String content reading methods

#define CONTENT_GETTER(type, value) \
do {\
type __value;\
OSSpinLockLock(&_contentsLock);\
__value = value;\
OSSpinLockUnlock(&_contentsLock);\
return __value;\
}\
while (0)

- (NSUInteger)length {
  CONTENT_GETTER(NSUInteger, [_contents length]);
}

- (NSString *)string {
  CONTENT_GETTER(NSString *, [_contents string]);
}

- (NSString *)stringInRange:(NSRange)range {
  CONTENT_GETTER(NSString *, [[_contents string] substringWithRange:range]);
}

- (NSRange)lineRangeForRange:(NSRange)range {
  CONTENT_GETTER(NSRange, [[_contents string] lineRangeForRange:range]);
}

#pragma mark - Attributed string content reading methods

- (NSAttributedString *)attributedString {
  CONTENT_GETTER(NSAttributedString *, [_contents copy]);
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range {
  CONTENT_GETTER(NSAttributedString *, [_contents attributedSubstringFromRange:range]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange {
  CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index effectiveRange:effectiveRange]);
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)effectiveRange inRange:(NSRange)rangeLimit {
  CONTENT_GETTER(id, [_contents attribute:attrName atIndex:index longestEffectiveRange:effectiveRange inRange:rangeLimit]);
}

#pragma mark - String content writing methods

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  
  // replacing an empty range with an empty string, no change required
  if (!range.length && ![string length]) {
    return;
  }
  
  // replacing a substring with an equal string, no change required
  if ([string isEqualToString:[self stringInRange:range]]) {
    return;
  }
  
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:self.defaultAttributes];
  OSSpinLockLock(&_pendingChangesLock);
  [self _processPendingChanges];
  
  OSSpinLockLock(&_contentsLock);
  if ([string length]) {
    [_contents replaceCharactersInRange:range withAttributedString:attributedString];
  } else {
    [_contents deleteCharactersInRange:range];
  }
  OSSpinLockUnlock(&_contentsLock);
  
  OSSpinLockUnlock(&_pendingChangesLock);
  for (id<FileBufferPresenter>presenter in [self presenters]) {
    if ([presenter respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withAttributedString:)]) {
      [presenter fileBuffer:self didReplaceCharactersInRange:range withAttributedString:attributedString];
    }
  }
}

#pragma mark - Attributed string content writing methods

#define CONTENT_MODIFIER(...) \
do {\
ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);\
if (!range.length) {\
return;\
}\
ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);\
OSSpinLockLock(&_pendingChangesLock);\
[_pendingChanges addObject:__VA_ARGS__];\
_hasPendingChanges = YES;\
[self _processPendingChanges];\
OSSpinLockUnlock(&_pendingChangesLock);\
}\
while (0)

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range {
  CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeAdd, _changeTypeKey, nil]);
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range {
  CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributeNames, _changeAttributeNamesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemove, _changeTypeKey, nil]);
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
  CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:attributes, _changeAttributesKey, [NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeSet, _changeTypeKey, nil]);
}

- (void)removeAllAttributesInRange:(NSRange)range {
  CONTENT_MODIFIER([NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], _changeRangeKey, _changeTypeAttributeRemoveAll, _changeTypeKey, nil]);
}

#pragma mark - Find and replace functionality
// TODO these need support for transactions, pending changes and be better integrated with the multithreaded content management system, but they have to be replaced by onigregexp anyway so I'm leaving them broken for the time being

-(NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  return [regexp numberOfMatchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  return [regexp matchesInString:[self string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  return [result.regularExpression replacementStringForResult:result inString:[self string] offset:offset template:replacementTemplate];
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(match && replacementTemplate);
  
  NSRange replacementRange = match.range;
  NSString *replacementString =  [self replacementStringForResult:match offset:offset template:replacementTemplate];
  
  replacementRange.location += offset;
  [self replaceCharactersInRange:replacementRange withString:replacementString];
  replacementRange.length = replacementString.length;
  return replacementRange;
}

#pragma mark - Private Methods

- (void)_setHasPendingChanges {
  ASSERT(!OSSpinLockTry(&_pendingChangesLock));
  if (_hasPendingChanges)
    return;
  _hasPendingChanges = YES;
  [NSOperationQueue.mainQueue addOperationWithBlock:^{
    OSSpinLockLock(&_pendingChangesLock);
    [self _processPendingChanges];
    OSSpinLockUnlock(&_pendingChangesLock);
  }];
}

- (void)_processPendingChanges
{
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(!OSSpinLockTry(&_pendingChangesLock));
  
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
    ASSERT(changeType && (changeType == _changeTypeAttributeAdd || changeType == _changeTypeAttributeRemove || changeType == _changeTypeAttributeSet|| changeType == _changeTypeAttributeRemoveAll));
    ASSERT([nextChange objectForKey:_changeRangeKey]);
    NSRange range = [[nextChange objectForKey:_changeRangeKey] rangeValue];
    
    OSSpinLockLock(&_contentsLock);
    if (changeType == _changeTypeAttributeAdd) {
      ASSERT([(NSDictionary *)[nextChange objectForKey:_changeAttributesKey] count]);
      [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
    } else if (changeType == _changeTypeAttributeRemove) {
      ASSERT([(NSArray *)[nextChange objectForKey:_changeAttributeNamesKey] count]);
      for (NSString *attributeName in [nextChange objectForKey:_changeAttributeNamesKey])
        [_contents removeAttribute:attributeName range:range];
    } else if (changeType == _changeTypeAttributeSet) {
      ASSERT([(NSDictionary *)[nextChange objectForKey:_changeAttributesKey] count]);
      [_contents setAttributes:self.defaultAttributes range:range];
      [_contents addAttributes:[nextChange objectForKey:_changeAttributesKey] range:range];
    } else if (changeType == _changeTypeAttributeRemoveAll) {
      [_contents setAttributes:self.defaultAttributes range:range];
    }
    OSSpinLockUnlock(&_contentsLock);
    
    for (id<FileBufferPresenter> presenter in [self presenters]) {
      if ([presenter respondsToSelector:@selector(fileBuffer:didChangeAttributesInRange:)]) {
        [presenter fileBuffer:self didChangeAttributesInRange:range];
      }
    }
    OSSpinLockLock(&_pendingChangesLock);
  }
}

@end
