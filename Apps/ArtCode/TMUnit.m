//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex.h"
#import "TMScope+Internal.h"
#import "TMTheme.h"
#import "TMBundle.h"
#import "TMSymbol.h"
#import "TMPreference.h"
#import "TMSyntaxNode.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "NSString+CStringCaching.h"
#import "NSIndexSet+StringRanges.h"
#import "FileBuffer.h"
#import "Operation.h"
#import <libkern/OSAtomic.h>

static NSMutableDictionary *_extensionClasses;

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;

@interface TMSymbol (Internal)

@property (nonatomic, readwrite) BOOL separator;
- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range;

@end

#pragma mark -

@interface AutodetectSyntaxOperation : Operation

/// Only accessible after the operation is finished
@property (atomic, strong, readonly) TMSyntaxNode *syntax;

- (id)initWithFileURL:(NSURL *)fileURL firstLine:(NSString *)firstLine completionHandler:(void(^)(BOOL success))completionHandler;

@end

#pragma mark -

@interface ReparseOperation : Operation

//- (id)initWithCodeUnit:(TMUnit *)codeUnit completionHandler:(void(^)(BOOL success))completionHandler;

@end

#pragma mark -

@interface Change : NSObject
{
  @package
  NSRange oldRange;
  NSRange newRange;
}
@end

#pragma mark -

@interface TMUnit () <FileBufferPresenter>

- (BOOL)_isUpToDate;
- (void)_queueBlockUntilUpToDate:(void(^)(void))block;
- (void)_setHasPendingChanges;
- (void)_generateScopes;
- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack;
- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope;
- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope;
- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern;

@end

#pragma mark -

@implementation TMUnit {
  NSOperationQueue *_internalQueue;
  AutodetectSyntaxOperation *_autodetectSyntaxOperation;
  ReparseOperation *_reparseOperation;
  FileBuffer *_fileBuffer;
  volatile int _fileBufferVersion;
  volatile int _scopesVersion;
  dispatch_semaphore_t _scopesLock;
  TMScope *_rootScope;
  dispatch_semaphore_t _pendingChangesLock;
  NSMutableArray *_pendingChanges;
  NSMutableIndexSet *_unparsedRanges;
  NSMutableDictionary *_patternsIncludedByPattern;
  NSMutableDictionary *_extensions;
}

@synthesize index = _index, syntax = _syntax;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [TMUnit class]) {
    return;
  }
  _numberedCapturesRegexp = [OnigRegexp compile:@"\\\\([1-9])" options:OnigOptionCaptureGroup];
  _namedCapturesRegexp = [OnigRegexp compile:@"\\\\k<(.*?)>" options:OnigOptionCaptureGroup];
  ASSERT(_numberedCapturesRegexp && _namedCapturesRegexp);
}

#pragma mark - FileBufferPresenter

- (void)fileBuffer:(FileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  Change *change = [[Change alloc] init];
  change->oldRange = range;
  change->newRange = NSMakeRange(range.location, [string length]);
  dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  [_pendingChanges addObject:change];
  [self _setHasPendingChanges];    
  dispatch_semaphore_signal(_pendingChangesLock);
}

#pragma mark - Public Methods

- (void)setSyntax:(TMSyntaxNode *)syntax {
  if (_autodetectSyntaxOperation) {
    [_autodetectSyntaxOperation cancel];
  }
  if (syntax == _syntax) {
    return;
  }
  _syntax = syntax;
  dispatch_semaphore_wait(_scopesLock, DISPATCH_TIME_FOREVER);
  _rootScope = [TMScope newRootScopeWithIdentifier:_syntax.identifier syntaxNode:_syntax];
  dispatch_semaphore_signal(_scopesLock);
  Change *firstChange = Change.alloc.init;
  firstChange->oldRange = NSMakeRange(0, 0);
  firstChange->newRange = NSMakeRange(0, _fileBuffer.length);
  dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  [_pendingChanges addObject:firstChange];
  [self _setHasPendingChanges];
  dispatch_semaphore_signal(_pendingChangesLock);
}

- (NSArray *)symbolList {
  return NSArray.alloc.init;
}

- (NSArray *)diagnostics {
  return NSArray.alloc.init;
}

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer fileURL:(NSURL *)fileURL index:(TMIndex *)index {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  self = [super init];
  if (!self) {
    return nil;
  }
  
  _fileBuffer = fileBuffer;
  [fileBuffer addPresenter:self];
  
  _scopesLock = dispatch_semaphore_create(1);
  _pendingChangesLock = dispatch_semaphore_create(1);
  _pendingChanges = NSMutableArray.alloc.init;
  
  _internalQueue = NSOperationQueue.alloc.init;
  _internalQueue.maxConcurrentOperationCount = 1;
  
  _unparsedRanges = NSMutableIndexSet.alloc.init;
  _patternsIncludedByPattern = NSMutableDictionary.alloc.init;

  _extensions = NSMutableDictionary.alloc.init;
  [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(NSString *extensionClassesSyntaxIdentifier, NSDictionary *extensionClasses, BOOL *outerStop) {
    if (![_syntax.identifier isEqualToString:extensionClassesSyntaxIdentifier])
      return;
    [extensionClasses enumerateKeysAndObjectsUsingBlock:^(NSString *extensionClassSyntaxIdentifier, Class extensionClass, BOOL *innerStop) {
      id extension = [[extensionClass alloc] initWithCodeUnit:self];
      if (!extension)
        return;
      [_extensions setObject:extension forKey:extensionClassSyntaxIdentifier];
    }];
  }];
  
  // Detect the syntax on the background queue so we don't initialize TMSyntaxNode on the main queue
  __weak TMUnit *weakSelf = self;
  NSString *firstLine = nil;
  if (fileBuffer) {
    NSRange firstLineRange = [fileBuffer lineRangeForRange:NSMakeRange(0, 0)];
    if (firstLineRange.length) {
      firstLine = [fileBuffer substringWithRange:firstLineRange];
    }
  }
  _autodetectSyntaxOperation = [AutodetectSyntaxOperation.alloc initWithFileURL:fileURL firstLine:firstLine completionHandler:^(BOOL success) {
    TMUnit *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (success) {
      strongSelf.syntax = strongSelf->_autodetectSyntaxOperation.syntax;
    }
    strongSelf->_autodetectSyntaxOperation = nil;
  }];
  [_internalQueue addOperation:_autodetectSyntaxOperation];

  return self;
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(TMScope *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [self _queueBlockUntilUpToDate:^{
    dispatch_semaphore_wait(_scopesLock, DISPATCH_TIME_FOREVER);
    NSMutableArray *scopeStack = [_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight];
    __block TMScope *scopeCopy = nil;
    [scopeStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TMScope *scope, NSUInteger depth, BOOL *stop) {
      if (!scope.identifier) {
        return;
      }
      scopeCopy = scope.copy;
      *stop = YES;
    }];
    dispatch_semaphore_signal(_scopesLock);
    completionHandler(scopeCopy);
  }];
}

- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(id<TMCompletionResultSet>))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [self _queueBlockUntilUpToDate:^{
    completionHandler((id<TMCompletionResultSet>)NSArray.alloc.init);
  }];
}

#pragma mark - Internal Methods

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key {
  if (!_extensionClasses) {
    _extensionClasses = NSMutableDictionary.alloc.init;
  }
  NSMutableDictionary *extensionClassesForLanguage = [_extensionClasses objectForKey:languageIdentifier];
  if (!extensionClassesForLanguage) {
    extensionClassesForLanguage = NSMutableDictionary.alloc.init;
    [_extensionClasses setObject:extensionClassesForLanguage forKey:languageIdentifier];
  }
  [extensionClassesForLanguage setObject:extensionClass forKey:key];
}

- (id)extensionForKey:(id)key {
  return [_extensions objectForKey:key];
}

#pragma mark - Private Methods

- (BOOL)_isUpToDate {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (!_syntax && !_autodetectSyntaxOperation) {
    return YES;
  }
  return _scopesVersion == _fileBufferVersion;
}

- (void)_queueBlockUntilUpToDate:(void (^)(void))block {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if ([self _isUpToDate]) {
    block();
  } else {
    [self performSelector:@selector(_queueBlockUntilUpToDate:) withObject:block afterDelay:0.2];
  }
}

- (void)_setHasPendingChanges {
  ASSERT(dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_NOW));
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  __weak TMUnit *weakSelf = self;
  OSAtomicIncrement32(&_fileBufferVersion);
  [_internalQueue addOperationWithBlock:^{
    TMUnit *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (!strongSelf->_syntax) {
      return;
    }
    dispatch_semaphore_wait(strongSelf->_scopesLock, DISPATCH_TIME_FOREVER);
    [strongSelf _generateScopes];
    dispatch_semaphore_signal(strongSelf->_scopesLock);
  }];
}

- (void)_generateScopes
{
  ASSERT(dispatch_semaphore_wait(_scopesLock, DISPATCH_TIME_NOW));
  ASSERT(NSOperationQueue.currentQueue == _internalQueue);
  
  // First of all, we apply all the pending changes to the scope tree, the unparsed ranges and the blank ranges
  dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  if (![_pendingChanges count]) {
    dispatch_semaphore_signal(_pendingChangesLock);
    return;
  }
  while ([_pendingChanges count])
  {
    Change *currentChange = [_pendingChanges objectAtIndex:0];
    [_pendingChanges removeObjectAtIndex:0];
    dispatch_semaphore_signal(_pendingChangesLock);
    // Save the change's generation as our starting generation, because new changes might be queued at any time outside of the lock, and we'd apply them too late then
    NSRange oldRange = currentChange->oldRange;
    NSRange newRange = currentChange->newRange;
    ASSERT(oldRange.location == newRange.location);
    // Adjust the scope tree to account for the change
    [_rootScope shiftByReplacingRange:oldRange withRange:newRange];
    // Replace the ranges in the unparsed ranges, add a placeholder if the change was a deletion so we know the part right after the deletion needs to be reparsed
    [_unparsedRanges replaceIndexesInRange:oldRange withIndexesInRange:newRange];
    if (!newRange.length)
      [_unparsedRanges addIndex:newRange.location];
    dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  }
  
  // Clip off unparsed ranges that are past the end of the file (it can happen because of placeholder ranges on deletion)
  NSUInteger fileLength = _fileBuffer.length;
  [_unparsedRanges removeIndexesInRange:NSMakeRange(fileLength, NSUIntegerMax - fileLength)];
  
  // Get the next unparsed range
  NSRange nextRange = [_unparsedRanges firstRange];
  dispatch_semaphore_signal(_pendingChangesLock);
  
  NSMutableArray *scopeStack = nil;
  
  // Parse the next range
  while (nextRange.location != NSNotFound)
  {
    // Get the first line range
    NSRange lineRange = NSMakeRange(nextRange.location, 0);
    lineRange = [_fileBuffer lineRangeForRange:lineRange];
    // Zero length line means end of file
    if (!lineRange.length)
      return;
    
    // Setup the scope stack
    if (!scopeStack)
      scopeStack = [_rootScope scopeStackAtOffset:lineRange.location options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
    if (!scopeStack)
      scopeStack = [NSMutableArray arrayWithObject:_rootScope];
    
    // Parse the range
    while (lineRange.location < NSMaxRange(nextRange))
    {
      // Mark the whole line as unparsed so we don't miss parts of it if we get interrupted
      dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
      [_unparsedRanges addIndexesInRange:lineRange];
      dispatch_semaphore_signal(_pendingChangesLock);
      
      // Delete all scopes in the line
      [_rootScope removeChildScopesInRange:lineRange];
      
      // Setup the line
      NSString *line = [_fileBuffer substringWithRange:lineRange];
      
      // Parse the line
      [self _generateScopesWithLine:line range:lineRange scopeStack:scopeStack];
      
      // Stretch all remaining scopes to cover to the end of the line
      for (TMScope *scope in scopeStack)
      {
        NSUInteger stretchedLength = NSMaxRange(lineRange) - scope.location;
        if (stretchedLength > scope.length)
          scope.length = stretchedLength;
      }
      
      // Remove the line range from the unparsed ranges
      dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
      [_unparsedRanges removeIndexesInRange:lineRange];
      dispatch_semaphore_signal(_pendingChangesLock);
      // proceed to next line
      NSRange oldLineRange = lineRange;
      lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
      lineRange = [_fileBuffer lineRangeForRange:lineRange];
      if (lineRange.location == oldLineRange.location) {
        break;
      }
    }
    // The lineRange now refers to the first line after the unparsed range we just finished parsing. Try to merge the scope tree at the start, if it fails, we'll have to parse the line manually
    BOOL mergeSuccessful = [_rootScope attemptMergeAtOffset:lineRange.location];
    
    // If we need to reparse the line, we add it to the unparsed ranges
    dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
    if (!mergeSuccessful)
      [_unparsedRanges addIndex:lineRange.location];
    // Get the next unparsed range
    nextRange = [_unparsedRanges firstRange];
    dispatch_semaphore_signal(_pendingChangesLock);
    
    // If we're reparsing the line, we can reuse the same scope stack, if not, we need to reset it to nil so the next cycle gets a new one
    if (mergeSuccessful)
      scopeStack = nil;
  }
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  [_rootScope performSelector:@selector(_checkConsistency)];
#pragma clang diagnostic pop
#endif
  
  OSAtomicCompareAndSwap32(_scopesVersion, _fileBufferVersion, &_scopesVersion);
}

- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack
{
  line = [line stringByCachingCString];
  NSUInteger position = 0;
  NSUInteger previousTokenStart = lineRange.location;
  NSUInteger lineEnd = NSMaxRange(lineRange);
  
  // Check for a span scope with a missing content scope
  {
    TMScope *scope = [scopeStack lastObject];
    if (scope.type == TMScopeTypeSpan && !(scope.flags & TMScopeHasContentScope) && scope.syntaxNode.contentName)
    {
      TMScope *contentScope = [scope newChildScopeWithIdentifier:scope.syntaxNode.contentName syntaxNode:scope.syntaxNode location:lineRange.location type:TMScopeTypeContent];
      ASSERT(scope.endRegexp);
      contentScope.endRegexp = scope.endRegexp;
      scope.flags |= TMScopeHasContentScope;
      [scopeStack addObject:contentScope];
    }
  }
  
  for (;;)
  {
    TMScope *scope = [scopeStack lastObject];
    TMSyntaxNode *syntaxNode = scope.syntaxNode;
    
    // Find the first matching pattern
    TMSyntaxNode *firstSyntaxNode = nil;
    OnigResult *firstResult = nil;
    NSArray *patterns = [self _patternsIncludedByPattern:syntaxNode];
    for (TMSyntaxNode *pattern in patterns)
    {
      OnigRegexp *patternRegexp = pattern.match;
      if (!patternRegexp)
        patternRegexp = pattern.begin;
      ASSERT(patternRegexp);
      OnigResult *result = [patternRegexp search:line start:position];
      if (!result || (firstResult && [firstResult bodyRange].location <= [result bodyRange].location))
        continue;
      firstResult = result;
      firstSyntaxNode = pattern;
    }
    
    // Find the end match
    OnigResult *endResult = [scope.endRegexp search:line start:position];
    
    ASSERT(!firstSyntaxNode || firstResult);
    
    // Handle the matches
    if (endResult && (!firstResult || [firstResult bodyRange].location >= [endResult bodyRange].location ))
    {
      // Handle end result first
      NSRange resultRange = [endResult bodyRange];
      resultRange.location += lineRange.location;
      // Handle content name nested scope
      if (scope.type == TMScopeTypeContent)
      {
        [self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope];
        previousTokenStart = resultRange.location;
        scope.length = resultRange.location - scope.location;
        if (!scope.length)
          [scope removeFromParent];
        [scopeStack removeLastObject];
        scope = [scopeStack lastObject];
      }
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:scope];
      previousTokenStart = NSMaxRange(resultRange);
      // Handle end captures
      if (resultRange.length && syntaxNode.endCaptures)
      {
        [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult type:TMScopeTypeEnd offset:lineRange.location parentScope:scope];
        if ([(NSDictionary *)[syntaxNode.endCaptures objectForKey:@"0"] objectForKey:_captureName]) {
          scope.flags |= TMScopeHasEndScope;
        }
      }
      scope.length = NSMaxRange(resultRange) - scope.location;
      scope.flags |= TMScopeHasEnd;
      if (!scope.length)
        [scope removeFromParent];
      ASSERT([scopeStack count]);
      [scopeStack removeLastObject];
      // We don't need to make sure position advances since we changed the stack
      // This could bite us if there's a begin and end regexp that match in the same position
      position = NSMaxRange([endResult bodyRange]);
    }
    else if (firstSyntaxNode.match)
    {
      // Handle a match pattern
      NSRange resultRange = [firstResult bodyRange];
      resultRange.location += lineRange.location;
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope];
      previousTokenStart = resultRange.location;
      if (resultRange.length)
      {
        TMScope *matchScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.identifier syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeMatch];
        matchScope.length = resultRange.length;
        [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:matchScope];
        previousTokenStart = NSMaxRange(resultRange);
        // Handle match pattern captures
        [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult type:TMScopeTypeMatch offset:lineRange.location parentScope:matchScope];
      }
      // We need to make sure position increases, or it would loop forever with a 0 width match
      position = NSMaxRange([firstResult bodyRange]);
      if (!resultRange.length)
        ++position;
    }
    else if (firstSyntaxNode.begin)
    {
      // Handle a new span pattern
      NSRange resultRange = [firstResult bodyRange];
      resultRange.location += lineRange.location;
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope];
      previousTokenStart = resultRange.location;
      TMScope *spanScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.identifier syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeSpan];
      spanScope.flags |= TMScopeHasBegin;
      // Create the end regexp
      NSMutableString *end = [NSMutableString stringWithString:firstSyntaxNode.end];
      [_numberedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
        int captureNumber = [[result stringAt:1] intValue];
        if (captureNumber >= 0 && [firstResult count] > captureNumber)
          return [firstResult stringAt:captureNumber];
        else
          return nil;
      }];
      [_namedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
        NSString *captureName = [result stringAt:1];
        int captureNumber = [firstResult indexForName:captureName];
        if (captureNumber >= 0 && [firstResult count] > captureNumber)
          return [firstResult stringAt:captureNumber];
        else
          return nil;
      }];
      spanScope.endRegexp = [OnigRegexp compile:end options:OnigOptionCaptureGroup];
      ASSERT(spanScope.endRegexp);
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:spanScope];
      previousTokenStart = NSMaxRange(resultRange);
      // Handle begin captures
      if (resultRange.length && firstSyntaxNode.beginCaptures)
      {
        [self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult type:TMScopeTypeBegin offset:lineRange.location parentScope:spanScope];
        if ([(NSDictionary *)[firstSyntaxNode.beginCaptures objectForKey:@"0"] objectForKey:_captureName]) {
          spanScope.flags |= TMScopeHasBeginScope;
        }
      }
      [scopeStack addObject:spanScope];
      // Handle content name nested scope
      if (firstSyntaxNode.contentName)
      {
        TMScope *contentScope = [spanScope newChildScopeWithIdentifier:firstSyntaxNode.contentName syntaxNode:firstSyntaxNode location:NSMaxRange(resultRange) type:TMScopeTypeContent];
        contentScope.endRegexp = spanScope.endRegexp;
        spanScope.flags |= TMScopeHasContentScope;
        [scopeStack addObject:contentScope];
      }
      // We don't need to make sure position advances since we changed the stack
      // This could bite us if there's a begin and end regexp that match in the same position
      position = NSMaxRange([firstResult bodyRange]);
    }
    else
    {
      break;
    }
    
    // We need to break if we hit the end of the line, failing to do so not only runs another cycle that doesn't find anything 99% of the time, but also can cause problems with matches that include the newline which have to be the last match for the line in the remaining 1% of the cases
    if (position >= lineRange.length)
      break;
  }
  [self _parsedTokenInRange:NSMakeRange(previousTokenStart, lineEnd - previousTokenStart) withScope:[scopeStack lastObject]];
}

- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope
{
  ASSERT(dispatch_semaphore_wait(_scopesLock, DISPATCH_TIME_NOW));
  ASSERT(NSOperationQueue.currentQueue == _internalQueue);
  ASSERT(type == TMScopeTypeMatch || type == TMScopeTypeBegin || type == TMScopeTypeEnd);
  ASSERT(scope && result && [result bodyRange].length);
  if (!dictionary || !result)
    return;
  TMScope *capturesScope = scope;
  if (type != TMScopeTypeMatch)
  {
    capturesScope = [scope newChildScopeWithIdentifier:[(NSDictionary *)[dictionary objectForKey:@"0"] objectForKey:_captureName] syntaxNode:nil location:[result bodyRange].location + offset type:type];
    capturesScope.length = [result bodyRange].length;
    [self _parsedTokenInRange:NSMakeRange(capturesScope.location, capturesScope.length) withScope:capturesScope];
  }
  NSMutableArray *capturesScopesStack = [NSMutableArray arrayWithObject:capturesScope];
  NSUInteger numMatchRanges = [result count];
  for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
  {
    NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
    currentMatchRange.location += offset;
    if (!currentMatchRange.length)
      continue;
    NSString *currentCaptureName = [(NSDictionary *)[dictionary objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
    if (!currentCaptureName)
      continue;
    while (currentMatchRange.location < capturesScope.location || NSMaxRange(currentMatchRange) > capturesScope.location + capturesScope.length)
    {
      ASSERT([capturesScopesStack count]);
      [capturesScopesStack removeLastObject];
      capturesScope = [capturesScopesStack lastObject];
    }
    TMScope *currentCaptureScope = [capturesScope newChildScopeWithIdentifier:currentCaptureName syntaxNode:nil location:currentMatchRange.location type:TMScopeTypeCapture];
    currentCaptureScope.length = currentMatchRange.length;
    [self _parsedTokenInRange:NSMakeRange(currentCaptureScope.location, currentCaptureScope.length) withScope:currentCaptureScope];
    [capturesScopesStack addObject:currentCaptureScope];
    capturesScope = currentCaptureScope;
  }
}

- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope
{
// TODO URI: queue up callbacks to call on main thread
  //  NSDictionary *attributes = [_fileBuffer.theme attributesForScope:scope];
  //  if (![attributes count])
  //    return;
  //  return [_fileBuffer setAttributes:attributes range:tokenRange expectedGeneration:generation];
}

- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern
{
  ASSERT(NSOperationQueue.currentQueue == _internalQueue);
  NSMutableArray *includedPatterns = [_patternsIncludedByPattern objectForKey:pattern];
  if (includedPatterns)
    return includedPatterns;
  if (!pattern.patterns)
    return nil;
  includedPatterns = [NSMutableArray arrayWithArray:pattern.patterns];
  NSMutableSet *dereferencedPatterns = [NSMutableSet set];
  NSMutableIndexSet *containerPatternIndexes = [NSMutableIndexSet indexSet];
  do
  {
    [containerPatternIndexes removeAllIndexes];
    [includedPatterns enumerateObjectsUsingBlock:^(TMSyntaxNode *obj, NSUInteger idx, BOOL *stop) {
      if ([obj match] || [obj begin])
        return;
      [containerPatternIndexes addIndex:idx];
    }];
    __block NSUInteger offset = 0;
    [containerPatternIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      TMSyntaxNode *containerPattern = [includedPatterns objectAtIndex:idx + offset];
      [includedPatterns removeObjectAtIndex:idx + offset];
      if ([dereferencedPatterns containsObject:containerPattern])
        return;
      ASSERT(containerPattern.include || containerPattern.patterns);
      ASSERT(!containerPattern.include || !containerPattern.patterns);
      if (containerPattern.include)
      {
        unichar firstCharacter = [containerPattern.include characterAtIndex:0];
        if (firstCharacter == '#')
        {
          TMSyntaxNode *patternSyntax = [containerPattern rootSyntax];
          [includedPatterns insertObject:[patternSyntax.repository objectForKey:[containerPattern.include substringFromIndex:1]] atIndex:idx + offset];
        }
        else
        {
          ASSERT(firstCharacter != '$' || [containerPattern.include isEqualToString:@"$base"] || [containerPattern.include isEqualToString:@"$self"]);
          TMSyntaxNode *includedSyntax = nil;
          if ([containerPattern.include isEqualToString:@"$base"])
            includedSyntax = _syntax;
          else if ([containerPattern.include isEqualToString:@"$self"])
            includedSyntax = [containerPattern rootSyntax];
          else
            includedSyntax = [TMSyntaxNode syntaxWithScopeIdentifier:containerPattern.include];
          [includedPatterns addObject:includedSyntax];
        }
      }
      else
      {
        NSUInteger patternsCount = [containerPattern.patterns count];
        ASSERT(patternsCount);
        [includedPatterns insertObjects:containerPattern.patterns atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx + offset, patternsCount)]];
        offset += patternsCount - 1;
      }
      [dereferencedPatterns addObject:containerPattern];
    }];
  }
  while ([containerPatternIndexes count]);
  [_patternsIncludedByPattern setObject:includedPatterns forKey:pattern];
  return includedPatterns;
}

@end
   
#pragma mark -

@implementation AutodetectSyntaxOperation {
  NSURL *_fileURL;
  NSString *_firstLine;
}

@synthesize syntax = _syntax;

- (void)main {
  TMSyntaxNode *syntax = nil;
  if (_firstLine) {
    syntax = [TMSyntaxNode syntaxForFirstLine:_firstLine];
  }
  if (self.isCancelled) {
    return;
  }
  if (!syntax && _fileURL) {
    syntax = [TMSyntaxNode syntaxForFileName:_fileURL.lastPathComponent];
  }
  if (self.isCancelled) {
    return;
  }
  if (!syntax) {
    syntax = TMSyntaxNode.defaultSyntax;
  }
  if (self.isCancelled) {
    return;
  }
  @synchronized(self) {
    _syntax = syntax;
  }
}

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  return [self initWithFileURL:nil firstLine:nil completionHandler:completionHandler];
}

- (TMSyntaxNode *)syntax {
  ASSERT(self.isFinished);
  @synchronized(self) {
    return _syntax;
  }
}

- (id)initWithFileURL:(NSURL *)fileURL firstLine:(NSString *)firstLine completionHandler:(void (^)(BOOL))completionHandler {
  self = [super initWithCompletionHandler:completionHandler];
  if (!self) {
    return nil;
  }
  self->_fileURL = fileURL;
  self->_firstLine = firstLine;
  return self;
}

@end

#pragma mark -

@implementation ReparseOperation



@end

#pragma mark -

@implementation Change
@end
