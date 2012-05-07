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
#import "Operation.h"


static NSMutableDictionary *_extensionClasses;

static NSString * const _qualifiedIdentifierAttributeName = @"TMUnitQualifiedIdentifierAttributeName";

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

/// Only accessible after the operation is finished
@property (atomic, strong, readonly) TMScope *rootScope;
@property (atomic, strong, readonly) NSAttributedString *attributedContent;

- (id)initWithFileContents:(NSString *)contents rootScope:(TMScope *)rootScope completionHandler:(void(^)(BOOL success))completionHandler;
- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack;
- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope;
- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope;

@end

#pragma mark -

@interface TMUnit ()

@property (nonatomic, strong) AutodetectSyntaxOperation *autodetectSyntaxOperation;
@property (nonatomic, strong) ReparseOperation *reparseOperation;
@property (nonatomic, getter = isUpToDate) BOOL upToDate;

- (void)_queueBlockUntilUpToDate:(void(^)(void))block;
- (void)_queueReparseOperation;

@end

#pragma mark -

@implementation TMUnit {
  NSOperationQueue *_internalQueue;
  
  NSString *_content;
  NSAttributedString *_attributedContent;
  
  TMScope *_rootScope;
  
  NSMutableArray *_queuedBlocks;
  
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
  return [self initWithFileURL:nil index:nil];
}

- (void)dealloc {
  [_internalQueue cancelAllOperations];
}

#pragma mark - Public Methods

- (void)setSyntax:(TMSyntaxNode *)syntax {
  [_internalQueue cancelAllOperations];
  _rootScope = nil;
  
  _syntax = syntax;
  
  if (_syntax) {
    [self _queueReparseOperation];
  }
  
  self.autodetectSyntaxOperation = nil;
}

- (NSArray *)symbolList {
  return NSArray.alloc.init;
}

- (NSArray *)diagnostics {
  return NSArray.alloc.init;
}

- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  self = [super init];
  if (!self) {
    return nil;
  }
  
  // TODO URI load the contents from the file
  _content = NSString.alloc.init;
  
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
  // TODO URI load the first line from the file
  NSString *firstLine = nil;
  _autodetectSyntaxOperation = [AutodetectSyntaxOperation.alloc initWithFileURL:fileURL firstLine:firstLine completionHandler:^(BOOL success) {
    if (success) {
      weakSelf.syntax = weakSelf.autodetectSyntaxOperation.syntax;
    }
    weakSelf.autodetectSyntaxOperation = nil;
  }];
  [_internalQueue addOperation:_autodetectSyntaxOperation];
  
  return self;
}

- (void)enumerateQualifiedScopeIdentifiersAsynchronouslyInRange:(NSRange)range withBlock:(void(^)(NSString *qualifiedScopeIdentifier, NSRange range, BOOL *stop))block {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [self _queueBlockUntilUpToDate:^{
    [_attributedContent enumerateAttribute:_qualifiedIdentifierAttributeName inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:block];
  }];
}

- (void)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(NSString *))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  [self _queueBlockUntilUpToDate:^{
    [[_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TMScope *scope, NSUInteger depth, BOOL *stop) {
      if (!scope.identifier) {
        return;
      }
      completionHandler(scope.qualifiedIdentifier);
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

- (void)reparseWithUnsavedContent:(NSString *)content {
  if (!content) {
    // TODO URI: get the file's contents through the index's coordination mechanism
    UNIMPLEMENTED_VOID();
  }
  _content = content.copy;
  [self _queueReparseOperation];
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

- (void)_queueReparseOperation {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  
  if (!_content || !_syntax) {
    return;
  }

  self.upToDate = NO;
  TMUnit *weakSelf = self;
  TMScope *rootScope = [TMScope newRootScopeWithIdentifier:_syntax.identifier syntaxNode:_syntax];
  [self.reparseOperation cancel];
  self.reparseOperation = [ReparseOperation.alloc initWithFileContents:_content rootScope:rootScope completionHandler:^(BOOL success) {
    // If the operation was cancelled we don't need to do anything
    if (!success) {
      return;
    }
    TMUnit *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    // Keep these asserts separate because they're triggered during multithreading, so debugging won't give the same results
    ASSERT(strongSelf.reparseOperation.isFinished);
    ASSERT(strongSelf.reparseOperation.rootScope);
    ASSERT(strongSelf.reparseOperation.attributedContent);
    strongSelf->_rootScope = strongSelf.reparseOperation.rootScope;
    strongSelf->_attributedContent = strongSelf.reparseOperation.attributedContent;
    strongSelf.reparseOperation = nil;
    strongSelf.upToDate = YES;
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
  _syntax = syntax;
}

#pragma mark - Operation

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  return [self initWithFileURL:nil firstLine:nil completionHandler:completionHandler];
}

#pragma mark - Public Methods

- (TMSyntaxNode *)syntax {
  ASSERT(self.isFinished);
  return _syntax;
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
  NSString *_contents;
}

@synthesize rootScope = _rootScope, attributedContent = _attributedContent;

#pragma mark - NSOperation

- (void)main {
  NSMutableArray *scopeStack = [NSMutableArray.alloc initWithObjects:_rootScope, nil];
  // Get the next unparsed range
  NSRange lineRange = [_contents lineRangeForRange:NSMakeRange(0, 0)];
  while (lineRange.length) {
    OPERATION_RETURN_IF_CANCELLED;    
    NSString *line = [_contents substringWithRange:lineRange];
    OPERATION_RETURN_IF_CANCELLED;
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
    // Check that we actually advance. It will get stuck here if the file ends without a newline.
    NSRange oldLineRange = lineRange;
    lineRange = [_contents lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
    if (lineRange.location == oldLineRange.location) {
      break;
    }
  }
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  [_rootScope performSelector:@selector(_checkConsistency)];
#pragma clang diagnostic pop
#endif
}

#pragma mark - Operation

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  return [self initWithFileContents:nil rootScope:nil completionHandler:nil];
}

#pragma mark - Public Methods

#if DEBUG

- (TMScope *)rootScope {
  ASSERT(self.isFinished);
  return _rootScope;
}

- (NSAttributedString *)attributedContent {
  ASSERT(self.isFinished);
  return _attributedContent;
}

#endif

- (id)initWithFileContents:(NSString *)contents rootScope:(TMScope *)rootScope completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(contents && rootScope);
  self = [super initWithCompletionHandler:completionHandler];
  if (!self) {
    return nil;
  }
  _contents = contents;
  _rootScope = rootScope;
  _attributedContent = [NSMutableAttributedString.alloc initWithString:contents];
  return self;
}

#pragma mark - Private Methods

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
        scope.flags |= TMScopeHasEndScope;
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
        spanScope.flags |= TMScopeHasBeginScope;
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
  [(NSMutableAttributedString *)_attributedContent addAttribute:_qualifiedIdentifierAttributeName value:scope.qualifiedIdentifier range:tokenRange];
}

@end
