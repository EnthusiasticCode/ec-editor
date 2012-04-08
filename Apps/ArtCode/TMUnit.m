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
#import "TMSymbol.h"
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

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer rootScope:(TMScope *)rootScope pendingChanges:(NSMutableArray *)pendingChanges pendingChangesLock:(dispatch_semaphore_t)pendingChangesLock unparsedRanges:(NSMutableIndexSet *)unparsedRanges completionHandler:(void(^)(BOOL success))completionHandler;
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

@property (nonatomic, strong) AutodetectSyntaxOperation *autodetectSyntaxOperation;
@property (nonatomic, strong) ReparseOperation *reparseOperation;
@property (nonatomic, getter = isUpToDate) BOOL upToDate;

- (void)_queueBlockUntilUpToDate:(void(^)(void))block;
- (void)_setHasPendingChanges;
- (void)_queueReparseOperation;
- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern;

@end

#pragma mark -

@implementation TMUnit {
  NSOperationQueue *_internalQueue;

  FileBuffer *_fileBuffer;
  
  TMScope *_rootScope;
  
  dispatch_semaphore_t _pendingChangesLock;
  NSMutableArray *_pendingChanges;
  
  NSMutableArray *_queuedBlocks;
  
  NSMutableIndexSet *_unparsedRanges;
  
  NSMutableDictionary *_extensions;
}

@synthesize index = _index, syntax = _syntax;
@synthesize autodetectSyntaxOperation = _autodetectSyntaxOperation, reparseOperation = _reparseOperation, upToDate = _upToDate;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [TMUnit class]) {
    return;
  }
  _numberedCapturesRegexp = [OnigRegexp compile:@"\\\\([1-9])" options:OnigOptionCaptureGroup];
  _namedCapturesRegexp = [OnigRegexp compile:@"\\\\k<(.*?)>" options:OnigOptionCaptureGroup];
  ASSERT(_numberedCapturesRegexp && _namedCapturesRegexp);
}

- (id)init {
  return [self initWithFileBuffer:nil fileURL:nil index:nil];
}

- (void)dealloc {
  [_internalQueue cancelAllOperations];
}

#pragma mark - FileBufferPresenter

- (void)fileBuffer:(FileBuffer *)fileBuffer didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  Change *change = Change.alloc.init;
  change->oldRange = range;
  change->newRange = NSMakeRange(range.location, string.length);
  dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
  [_pendingChanges addObject:change];
  dispatch_semaphore_signal(_pendingChangesLock);
  [self _setHasPendingChanges];    
}

#pragma mark - Public Methods

- (void)setSyntax:(TMSyntaxNode *)syntax {
  [_internalQueue cancelAllOperations];
  [_fileBuffer removePresenter:self];
  _pendingChanges = nil;
  _unparsedRanges = nil;
  _rootScope = nil;
  
  _syntax = syntax;
    
  if (_syntax) {
    _rootScope = [TMScope newRootScopeWithIdentifier:_syntax.identifier syntaxNode:_syntax];
  }
  
  if (_syntax) {
    _pendingChanges = NSMutableArray.alloc.init;
    _unparsedRanges = NSMutableIndexSet.alloc.init;
    Change *firstChange = Change.alloc.init;
    firstChange->oldRange = NSMakeRange(0, 0);
    firstChange->newRange = NSMakeRange(0, _fileBuffer.length);
    [_pendingChanges addObject:firstChange];
    [self _queueReparseOperation];
    [_fileBuffer addPresenter:self];
  }
  self.autodetectSyntaxOperation = nil;
}

- (NSArray *)symbolList {
  return NSArray.alloc.init;
}

- (NSArray *)diagnostics {
  return NSArray.alloc.init;
}

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer fileURL:(NSURL *)fileURL index:(TMIndex *)index {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(fileBuffer || fileURL);
  self = [super init];
  if (!self) {
    return nil;
  }
  
  _fileBuffer = fileBuffer;
  
  _pendingChangesLock = dispatch_semaphore_create(1);
  
  _internalQueue = NSOperationQueue.alloc.init;
  _internalQueue.maxConcurrentOperationCount = 1;
  
  _queuedBlocks = NSMutableArray.alloc.init;
  
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
    if (success) {
      weakSelf.syntax = weakSelf.autodetectSyntaxOperation.syntax;
    }
    weakSelf.autodetectSyntaxOperation = nil;
  }];
  [_internalQueue addOperation:_autodetectSyntaxOperation];
  
  return self;
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(TMScope *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [self _queueBlockUntilUpToDate:^{
    [[_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TMScope *scope, NSUInteger depth, BOOL *stop) {
      if (!scope.identifier) {
        return;
      }
      completionHandler(scope.copy);
      *stop = YES;
    }];
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

- (void)setAutodetectSyntaxOperation:(AutodetectSyntaxOperation *)autodetectSyntaxOperation {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (autodetectSyntaxOperation == _autodetectSyntaxOperation) {
    return;
  }
  _autodetectSyntaxOperation = autodetectSyntaxOperation;
  if (!_autodetectSyntaxOperation && !self.reparseOperation) {
    self.upToDate = YES;
  }
}

- (void)setReparseOperation:(ReparseOperation *)reparseOperation {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (reparseOperation == _reparseOperation) {
    return;
  }
  _reparseOperation = reparseOperation;
  if (!_reparseOperation && !self.autodetectSyntaxOperation) {
    self.upToDate = YES;
  }
}

- (void)setUpToDate:(BOOL)upToDate {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (upToDate == _upToDate) {
    return;
  }
  _upToDate = upToDate;
  if (_upToDate) {
    for (void(^block)(void) in _queuedBlocks) {
      block();
    }
  }
}

- (void)_queueBlockUntilUpToDate:(void (^)(void))block {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  if (self.isUpToDate) {
    block();
  } else {
    [_queuedBlocks addObject:block];
  }
}

- (void)_setHasPendingChanges {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  
  // If we're not up to date an operation is already running
  if (!self.isUpToDate) {
    return;
  }
  
  // If we don't have a root scope it means we don't have a syntax, and we can't parse
  if (!_rootScope) {
    ASSERT(!_syntax);
    return;
  }
  
  [self _queueReparseOperation];
}

- (void)_queueReparseOperation {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);

  TMUnit *weakSelf = self;
  self.reparseOperation = [ReparseOperation.alloc initWithFileBuffer:_fileBuffer rootScope:_rootScope pendingChanges:_pendingChanges pendingChangesLock:_pendingChangesLock unparsedRanges:_unparsedRanges completionHandler:^(BOOL success) {
    // If the operation was cancelled we don't need to do anything
    if (!success) {
      return;
    }
    
    TMUnit *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    
    // If we have pending changes, we need to rerun the operation
    dispatch_semaphore_wait(strongSelf->_pendingChangesLock, DISPATCH_TIME_FOREVER);
    if (strongSelf->_pendingChanges.count) {
      [strongSelf _queueReparseOperation];
      dispatch_semaphore_signal(strongSelf->_pendingChangesLock);
      return;
    } else {
      dispatch_semaphore_signal(strongSelf->_pendingChangesLock);
      strongSelf.reparseOperation = nil;
    }
  }];
  [_internalQueue addOperation:self.reparseOperation];
}

@end
   
#pragma mark -

@implementation AutodetectSyntaxOperation {
  NSURL *_fileURL;
  NSString *_firstLine;
}

@synthesize syntax = _syntax;

#pragma mark - NSOperation

- (void)main {
  TMSyntaxNode *syntax = nil;
  if (_firstLine) {
    syntax = [TMSyntaxNode syntaxForFirstLine:_firstLine];
  }
  OPERATION_RETURN_IF_CANCELLED;
  if (!syntax && _fileURL) {
    syntax = [TMSyntaxNode syntaxForFileName:_fileURL.lastPathComponent];
  }
  OPERATION_RETURN_IF_CANCELLED;
  if (!syntax) {
    syntax = TMSyntaxNode.defaultSyntax;
  }
  OPERATION_RETURN_IF_CANCELLED;
  @synchronized(self) {
    _syntax = syntax;
  }
}

#pragma mark - Operation

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  return [self initWithFileURL:nil firstLine:nil completionHandler:completionHandler];
}

#pragma mark - Public Methods

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
  TMScope *_rootScope;
  dispatch_semaphore_t _pendingChangesLock;
  NSMutableArray *_pendingChanges;
  NSMutableIndexSet *_unparsedRanges;
}

#pragma mark - NSOperation

- (void)main {  
  // The whole operation is wrapped in this lock. Remember to signal it if we return early from it.
  // The root scope is inconsistent with the fileBuffer while we're running it, so the codeUnit should not be accessing it anyway.
  [self _generateScopes];
}

#pragma mark - Operation

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  return [self initWithFileBuffer:nil rootScope:nil pendingChanges:nil pendingChangesLock:NULL unparsedRanges:nil completionHandler:nil];
}

#pragma mark - Public Methods

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer rootScope:(TMScope *)rootScope pendingChanges:(NSMutableArray *)pendingChanges pendingChangesLock:(dispatch_semaphore_t)pendingChangesLock unparsedRanges:(NSMutableIndexSet *)unparsedRanges completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(fileBuffer && rootScope && pendingChanges && pendingChangesLock && unparsedRanges);
  self = [super initWithCompletionHandler:completionHandler];
  if (!self) {
    return nil;
  }
  _fileBuffer = fileBuffer;
  _rootScope = rootScope;
  _pendingChanges = pendingChanges;
  _pendingChangesLock = pendingChangesLock;
  _unparsedRanges = unparsedRanges;
  return self;
}

#pragma mark - Private Methods

- (void)_generateScopes {
  NSMutableArray *scopeStack = nil;
    
  for (;;) {
    OPERATION_RETURN_IF_CANCELLED;

    // First of all, we apply all the pending changes to the scope tree and the unparsed ranges
    dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_FOREVER);
    [self _processChanges];
    dispatch_semaphore_signal(_pendingChangesLock);
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Get the next unparsed range
    NSRange unparsedRange = [_unparsedRanges firstRange];
    
    // Get the first line range
    NSRange lineRange = [_fileBuffer lineRangeForRange:NSMakeRange(unparsedRange.location, 0)];
    // Check if we got a valid range, if we didn't, we're done parsing
    if (!lineRange.length || NSMaxRange(lineRange) == unparsedRange.location) {
      break;
    }
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Setup the scope stack
    if (!scopeStack) {
      scopeStack = [_rootScope scopeStackAtOffset:lineRange.location options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
      ASSERT(scopeStack);
    }
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Mark the whole line as unparsed so we don't miss parts of it if we get interrupted
    [_unparsedRanges addIndexesInRange:lineRange];
    
    // Delete all scopes in the line
    [_rootScope removeChildScopesInRange:lineRange];
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Setup the line
    NSString *line = nil;
    @try {
      line = [_fileBuffer substringWithRange:lineRange];
    } @catch (NSException *exception) {
      // If we get an exception it's probably because the fileBuffer was changed, just restart the loop in that case
      continue;
    }
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Parse the line
    [self _generateScopesWithLine:line range:lineRange scopeStack:scopeStack];
    
    OPERATION_RETURN_IF_CANCELLED;
    
    // Stretch all remaining scopes to cover to the end of the line
    for (TMScope *scope in scopeStack)
    {
      NSUInteger stretchedLength = NSMaxRange(lineRange) - scope.location;
      if (stretchedLength > scope.length)
        scope.length = stretchedLength;
    }
    
    OPERATION_RETURN_IF_CANCELLED;

    // Remove the line range from the unparsed ranges
    [_unparsedRanges removeIndexesInRange:lineRange];
    
    // If we're at the end of the unparsed range attempt to merge the scopes with the subsequent parsed range.
    NSUInteger lineEnd = NSMaxRange(lineRange);
    if (lineEnd >= NSMaxRange(unparsedRange)) {
      // If the merge is successful, reset the scope stack for the next unparsed range, otherwise add the end of the line to the unparsed ranges and continue from there
      if ([_rootScope attemptMergeAtOffset:lineEnd]) {
        scopeStack = nil;
      } else {
        [_unparsedRanges addIndex:lineEnd];
      }
    }
  }
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  [_rootScope performSelector:@selector(_checkConsistency)];
#pragma clang diagnostic pop
#endif
}

- (void)_processChanges {
  ASSERT(dispatch_semaphore_wait(_pendingChangesLock, DISPATCH_TIME_NOW));
  
  // Process the pending changes.
  // Unlock / relock within the loop so we don't block the pending changes too long at the time and also get rapid subsequent changes i.e. when someone is typing.
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
  line = [line stringByCachingCString];
  NSUInteger position = 0;
  NSUInteger previousTokenStart = lineRange.location;
  NSUInteger lineEnd = NSMaxRange(lineRange);
  
  // Check for a span scope with a missing content scope
  {
    TMScope *scope = [scopeStack lastObject];
    if (scope.type == TMScopeTypeSpan && !(scope.flags & TMScopeHasContentScope) && scope.syntaxNode.contentName) {
      TMScope *contentScope = [scope newChildScopeWithIdentifier:scope.syntaxNode.contentName syntaxNode:scope.syntaxNode location:lineRange.location type:TMScopeTypeContent];
      ASSERT(scope.endRegexp);
      contentScope.endRegexp = scope.endRegexp;
      scope.flags |= TMScopeHasContentScope;
      [scopeStack addObject:contentScope];
    }
  }
  
  for (;;) {
    TMScope *scope = [scopeStack lastObject];
    TMSyntaxNode *syntaxNode = scope.syntaxNode;
    
    // Find the first matching pattern
    TMSyntaxNode *firstSyntaxNode = nil;
    OnigResult *firstResult = nil;
    NSArray *patterns = [syntaxNode includedNodesWithRootNode:_rootScope.syntaxNode];
    for (TMSyntaxNode *pattern in patterns) {
      OnigRegexp *patternRegexp = pattern.match;
      if (!patternRegexp) {
        patternRegexp = pattern.begin;
      }
      ASSERT(patternRegexp);
      OnigResult *result = [patternRegexp search:line start:position];
      if (!result || (firstResult && [firstResult bodyRange].location <= [result bodyRange].location)) {
        continue;
      }
      firstResult = result;
      firstSyntaxNode = pattern;
    }
    
    // Find the end match
    OnigResult *endResult = [scope.endRegexp search:line start:position];
    
    ASSERT(!firstSyntaxNode || firstResult);
    
    // Handle the matches
    if (endResult && (!firstResult || [firstResult bodyRange].location >= [endResult bodyRange].location )) {
      // Handle end result first
      NSRange resultRange = [endResult bodyRange];
      resultRange.location += lineRange.location;
      // Handle content name nested scope
      if (scope.type == TMScopeTypeContent) {
        [self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope];
        previousTokenStart = resultRange.location;
        scope.length = resultRange.location - scope.location;
        if (!scope.length) {
          [scope removeFromParent];
        }
        [scopeStack removeLastObject];
        scope = [scopeStack lastObject];
      }
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:scope];
      previousTokenStart = NSMaxRange(resultRange);
      // Handle end captures
      if (resultRange.length && syntaxNode.endCaptures) {
        [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult type:TMScopeTypeEnd offset:lineRange.location parentScope:scope];
        if ([(NSDictionary *)[syntaxNode.endCaptures objectForKey:@"0"] objectForKey:_captureName]) {
          scope.flags |= TMScopeHasEndScope;
        }
      }
      scope.length = NSMaxRange(resultRange) - scope.location;
      scope.flags |= TMScopeHasEnd;
      if (!scope.length) {
        [scope removeFromParent];
      }
      ASSERT([scopeStack count]);
      [scopeStack removeLastObject];
      // We don't need to make sure position advances since we changed the stack
      // This could bite us if there's a begin and end regexp that match in the same position
      position = NSMaxRange([endResult bodyRange]);
    } else if (firstSyntaxNode.match) {
      // Handle a match pattern
      NSRange resultRange = [firstResult bodyRange];
      resultRange.location += lineRange.location;
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope];
      previousTokenStart = resultRange.location;
      if (resultRange.length) {
        TMScope *matchScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.identifier syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeMatch];
        matchScope.length = resultRange.length;
        [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:matchScope];
        previousTokenStart = NSMaxRange(resultRange);
        // Handle match pattern captures
        [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult type:TMScopeTypeMatch offset:lineRange.location parentScope:matchScope];
      }
      // We need to make sure position increases, or it would loop forever with a 0 width match
      position = NSMaxRange([firstResult bodyRange]);
      if (!resultRange.length) {
        ++position;
      }
    } else if (firstSyntaxNode.begin) {
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
        if (captureNumber >= 0 && [firstResult count] > captureNumber) {
          return [firstResult stringAt:captureNumber];
        } else {
          return nil;
        }
      }];
      [_namedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
        NSString *captureName = [result stringAt:1];
        int captureNumber = [firstResult indexForName:captureName];
        if (captureNumber >= 0 && [firstResult count] > captureNumber) {
          return [firstResult stringAt:captureNumber];
        } else {
          return nil;
        }
      }];
      spanScope.endRegexp = [OnigRegexp compile:end options:OnigOptionCaptureGroup];
      ASSERT(spanScope.endRegexp);
      [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:spanScope];
      previousTokenStart = NSMaxRange(resultRange);
      // Handle begin captures
      if (resultRange.length && firstSyntaxNode.beginCaptures) {
        [self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult type:TMScopeTypeBegin offset:lineRange.location parentScope:spanScope];
        if ([(NSDictionary *)[firstSyntaxNode.beginCaptures objectForKey:@"0"] objectForKey:_captureName]) {
          spanScope.flags |= TMScopeHasBeginScope;
        }
      }
      [scopeStack addObject:spanScope];
      // Handle content name nested scope
      if (firstSyntaxNode.contentName) {
        TMScope *contentScope = [spanScope newChildScopeWithIdentifier:firstSyntaxNode.contentName syntaxNode:firstSyntaxNode location:NSMaxRange(resultRange) type:TMScopeTypeContent];
        contentScope.endRegexp = spanScope.endRegexp;
        spanScope.flags |= TMScopeHasContentScope;
        [scopeStack addObject:contentScope];
      }
      // We don't need to make sure position advances since we changed the stack
      // This could bite us if there's a begin and end regexp that match in the same position
      position = NSMaxRange([firstResult bodyRange]);
    } else {
      break;
    }
    
    // We need to break if we hit the end of the line, failing to do so not only runs another cycle that doesn't find anything 99% of the time, but also can cause problems with matches that include the newline which have to be the last match for the line in the remaining 1% of the cases
    if (position >= lineRange.length) {
      break;
    }
  }
  [self _parsedTokenInRange:NSMakeRange(previousTokenStart, lineEnd - previousTokenStart) withScope:[scopeStack lastObject]];
}

- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope {
  ASSERT(type == TMScopeTypeMatch || type == TMScopeTypeBegin || type == TMScopeTypeEnd);
  ASSERT(scope && result && [result bodyRange].length);
  if (!dictionary || !result) {
    return;
  }
  TMScope *capturesScope = scope;
  if (type != TMScopeTypeMatch) {
    capturesScope = [scope newChildScopeWithIdentifier:[(NSDictionary *)[dictionary objectForKey:@"0"] objectForKey:_captureName] syntaxNode:nil location:[result bodyRange].location + offset type:type];
    capturesScope.length = [result bodyRange].length;
    [self _parsedTokenInRange:NSMakeRange(capturesScope.location, capturesScope.length) withScope:capturesScope];
  }
  NSMutableArray *capturesScopesStack = [NSMutableArray arrayWithObject:capturesScope];
  NSUInteger numMatchRanges = [result count];
  for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex) {
    NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
    currentMatchRange.location += offset;
    if (!currentMatchRange.length) {
      continue;
    }
    NSString *currentCaptureName = [(NSDictionary *)[dictionary objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
    if (!currentCaptureName) {
      continue;
    }
    while (currentMatchRange.location < capturesScope.location || NSMaxRange(currentMatchRange) > capturesScope.location + capturesScope.length) {
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

- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope {
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
