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

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer rootScope:(TMScope *)rootScope rootScopeLock:(dispatch_semaphore_t)rootScopeLock pendingChanges:(NSMutableArray *)pendingChanges pendingChangesLock:(dispatch_semaphore_t)pendingChangesLock unparsedRanges:(NSMutableIndexSet *)unparsedRanges completionHandler:(void(^)(BOOL success))completionHandler;
- (void)_generateScopes;
- (void)_processChanges;
- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack;
- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope;
- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope;

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
  
  dispatch_semaphore_t _rootScopeLock;
  TMScope *_rootScope;
  
  dispatch_semaphore_t _pendingChangesLock;
  NSMutableArray *_pendingChanges;
  
  NSMutableIndexSet *_unparsedRanges;
  
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
  dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_FOREVER);
  _rootScope = [TMScope newRootScopeWithIdentifier:_syntax.identifier syntaxNode:_syntax];
  dispatch_semaphore_signal(_rootScopeLock);
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
  
  _rootScopeLock = dispatch_semaphore_create(1);
  _pendingChangesLock = dispatch_semaphore_create(1);
  _pendingChanges = NSMutableArray.alloc.init;
  
  _internalQueue = NSOperationQueue.alloc.init;
  _internalQueue.maxConcurrentOperationCount = 1;
  
  _unparsedRanges = NSMutableIndexSet.alloc.init;

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
    dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_FOREVER);
    NSMutableArray *scopeStack = [_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight];
    __block TMScope *scopeCopy = nil;
    [scopeStack enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TMScope *scope, NSUInteger depth, BOOL *stop) {
      if (!scope.identifier) {
        return;
      }
      scopeCopy = scope.copy;
      *stop = YES;
    }];
    dispatch_semaphore_signal(_rootScopeLock);
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
  ++_fileBufferVersion;
  if (_rootScope) {
    [_internalQueue addOperation:[ReparseOperation.alloc initWithFileBuffer:_fileBuffer rootScope:_rootScope rootScopeLock:_rootScopeLock pendingChanges:_pendingChanges pendingChangesLock:_pendingChangesLock unparsedRanges:_unparsedRanges completionHandler:^(BOOL success) {
      _scopesVersion = _fileBufferVersion;
    }]];
  }
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

@implementation ReparseOperation {
  FileBuffer *_fileBuffer;
  dispatch_semaphore_t _rootScopeLock;
  TMScope *_rootScope;
  dispatch_semaphore_t _pendingChangesLock;
  NSMutableArray *_pendingChanges;
  NSMutableIndexSet *_unparsedRanges;
}

#pragma mark - NSOperation

- (void)main {  
  // The whole operation is wrapped in this lock. Remember to signal it if we return early from it.
  // The root scope is inconsistent with the fileBuffer while we're running it, so the codeUnit should not be accessing it anyway.
  dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_FOREVER);
  [self _generateScopes];
  dispatch_semaphore_signal(_rootScopeLock);
}

#pragma mark - Public Methods

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer rootScope:(TMScope *)rootScope rootScopeLock:(dispatch_semaphore_t)rootScopeLock pendingChanges:(NSMutableArray *)pendingChanges pendingChangesLock:(dispatch_semaphore_t)pendingChangesLock unparsedRanges:(NSMutableIndexSet *)unparsedRanges completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(fileBuffer && rootScope && rootScopeLock && pendingChanges && pendingChangesLock && unparsedRanges);
  self = [super initWithCompletionHandler:completionHandler];
  if (!self) {
    return nil;
  }
  _fileBuffer = fileBuffer;
  _rootScope = rootScope;
  _rootScopeLock = rootScopeLock;
  _pendingChanges = pendingChanges;
  _pendingChangesLock = pendingChangesLock;
  _unparsedRanges = unparsedRanges;
  return self;
}

#pragma mark - Private Methods

- (void)_generateScopes {
  ASSERT(dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_NOW));

  // Get the fileBuffer's length for later
  NSUInteger fileLength = _fileBuffer.length;
  
  // First of all, we apply all the pending changes to the scope tree and the unparsed ranges
  dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  [self _processChanges];
  dispatch_semaphore_signal(_pendingChangesLock);
  
  // Clip off unparsed ranges that are past the end of the file (it can happen because of placeholder ranges on deletion)
  // We use the length we got before processing the changes so we avoid a race condition which would cause us to lose unparsed ranges if the file gets shorter between when we're done processing the changes and we get the file length
  [_unparsedRanges removeIndexesInRange:NSMakeRange(fileLength, NSUIntegerMax - fileLength)];
  
  // Get the next unparsed range
  NSRange nextRange = [_unparsedRanges firstRange];
  
  NSMutableArray *scopeStack = nil;
  
  // Parse the next range
  while (nextRange.location != NSNotFound)
  {
    // Get the first line range
    NSRange lineRange = NSMakeRange(nextRange.location, 0);
    lineRange = [_fileBuffer lineRangeForRange:lineRange];
    // Zero length line means end of file
    if (!lineRange.length) {
      return;
    }
    
    // Setup the scope stack
    if (!scopeStack)
      scopeStack = [_rootScope scopeStackAtOffset:lineRange.location options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
    if (!scopeStack)
      scopeStack = [NSMutableArray arrayWithObject:_rootScope];
    
    // Parse the range
    while (lineRange.location < NSMaxRange(nextRange))
    {
      // Mark the whole line as unparsed so we don't miss parts of it if we get interrupted
      [_unparsedRanges addIndexesInRange:lineRange];
      
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
      [_unparsedRanges removeIndexesInRange:lineRange];
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
    if (!mergeSuccessful)
      [_unparsedRanges addIndex:lineRange.location];
    // Get the next unparsed range
    nextRange = [_unparsedRanges firstRange];
    
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
}

- (void)_processChanges {
  ASSERT(dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_NOW));
  ASSERT(dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_NOW));
  
  while ([_pendingChanges count]) {
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
    if (!newRange.length) {
      [_unparsedRanges addIndex:newRange.location];
    }
    dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  }
}

- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack {
  ASSERT(dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_NOW));

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
    NSArray *patterns = [syntaxNode includedNodesWithRootNode:_rootScope.syntaxNode];
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
  ASSERT(dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_NOW));
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
  ASSERT(dispatch_semaphore_wait(_rootScopeLock, DISPATCH_TIME_NOW));

  // TODO URI: queue up callbacks to call on main thread
  //  NSDictionary *attributes = [_fileBuffer.theme attributesForScope:scope];
  //  if (![attributes count])
  //    return;
  //  return [_fileBuffer setAttributes:attributes range:tokenRange expectedGeneration:generation];
}

@end

#pragma mark -

@implementation Change
@end











































