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
#import "TMSyntaxNode.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "NSString+CStringCaching.h"
#import "NSIndexSet+StringRanges.h"
#import "TMPreference.h"
#import "DiffMatchPatch.h"


static NSMutableDictionary *_extensionClasses;

static NSString * const _qualifiedIdentifierAttributeName = @"TMUnitQualifiedIdentifierAttributeName";

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;

#pragma mark -

@interface TMUnit ()

- (void)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack;
- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope;
- (void)_startScope:(TMScope *)scope;
- (void)_endScope:(TMScope *)scope;
- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope;

@end

#pragma mark -

@implementation TMUnit {
  NSString *_lastContent;
  NSMutableAttributedString *_attributedContent;
  
  TMScope *_rootScope;
  NSMutableArray *_symbolList;
  TMScope *_currentSymbol;
  
  NSMutableDictionary *_extensions;
}

@synthesize index = _index, syntax = _syntax, symbolList = _symbolList, diagnostics = _diagnostics;

- (NSArray *)symbolList {
  return [_symbolList copy];
}

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
  UNIMPLEMENTED();
}

#pragma mark - Public Methods

- (id)initWithFileURL:(NSURL *)fileURL syntax:(TMSyntaxNode *)syntax index:(TMIndex *)index {
  ASSERT(fileURL && syntax);
  self = [super init];
  if (!self) {
    return nil;
  }
  
  _syntax = syntax;
  
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
    
  return self;
}

- (void)enumerateQualifiedScopeIdentifiersInRange:(NSRange)range withBlock:(void(^)(NSString *qualifiedScopeIdentifier, NSRange range, BOOL *stop))block {
  [_attributedContent enumerateAttribute:_qualifiedIdentifierAttributeName inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:block];
}

- (NSString *)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset {
  __block NSString *qualifiedScopeIdentifier = nil;
  [[_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TMScope *scope, NSUInteger depth, BOOL *stop) {
    qualifiedScopeIdentifier = scope.qualifiedIdentifier;
    *stop = YES;
  }];
  if (!qualifiedScopeIdentifier) {
    qualifiedScopeIdentifier = self.syntax.identifier;
  }
  return qualifiedScopeIdentifier;
}

- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset {
  return (id<TMCompletionResultSet>)NSArray.alloc.init;
}

- (void)reparseWithUnsavedContent:(NSString *)content {
  content = content.copy;
  [self willChangeValueForKey:@"symbolList"];
  [self willChangeValueForKey:@"diagnostics"];
  _rootScope = [TMScope newRootScopeWithIdentifier:_syntax.identifier syntaxNode:_syntax];
  _symbolList = [NSMutableArray alloc].init;
  _diagnostics = [NSMutableArray alloc].init;
  _attributedContent = [NSMutableAttributedString.alloc initWithString:content];
  NSMutableArray *scopeStack = [NSMutableArray.alloc initWithObjects:_rootScope, nil];
  [self _startScope:_rootScope];
  // Get the next unparsed range
  NSRange lineRange = [content lineRangeForRange:NSMakeRange(0, 0)];
  while (lineRange.length) {
    NSString *line = [content substringWithRange:lineRange];
    [self _generateScopesWithLine:line range:lineRange scopeStack:scopeStack];
    // Stretch all remaining scopes to cover to the end of the line
    for (TMScope *scope in scopeStack)
    {
      NSUInteger stretchedLength = NSMaxRange(lineRange) - scope.location;
      if (stretchedLength > scope.length)
        scope.length = stretchedLength;
    }
    // Check that we actually advance. It will get stuck here if the file ends without a newline.
    NSRange oldLineRange = lineRange;
    lineRange = [content lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
    if (lineRange.location == oldLineRange.location) {
      break;
    }
  }
  // At the end of the parse close all remaining open scopes
  for (TMScope *scope in scopeStack.reverseObjectEnumerator) {
    [self _endScope:scope];
  }
  [self didChangeValueForKey:@"symbolList"];
  [self didChangeValueForKey:@"diagnostics"];
  
  _lastContent = content;
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  [_rootScope performSelector:@selector(_checkConsistency)];
#pragma clang diagnostic pop
#endif
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
      [self _startScope:contentScope];
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
        } else {
          [self _endScope:scope];
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
      } else {
        [self _endScope:scope];
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
        [self _startScope:matchScope];
        [self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:matchScope];
        previousTokenStart = NSMaxRange(resultRange);
        // Handle match pattern captures
        [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult type:TMScopeTypeMatch offset:lineRange.location parentScope:matchScope];
        [self _endScope:matchScope];
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
      [self _startScope:spanScope];
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
        [self _startScope:contentScope];
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
    [self _startScope:capturesScope];
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
      [self _endScope:capturesScope];
      [capturesScopesStack removeLastObject];
      capturesScope = [capturesScopesStack lastObject];
    }
    TMScope *currentCaptureScope = [capturesScope newChildScopeWithIdentifier:currentCaptureName syntaxNode:nil location:currentMatchRange.location type:TMScopeTypeCapture];
    currentCaptureScope.length = currentMatchRange.length;
    [self _parsedTokenInRange:NSMakeRange(currentCaptureScope.location, currentCaptureScope.length) withScope:currentCaptureScope];
    [self _startScope:currentCaptureScope];
    [capturesScopesStack addObject:currentCaptureScope];
    capturesScope = currentCaptureScope;
  }
  if (capturesScope != scope) {
    [self _endScope:capturesScope];
  }
}

- (void)_startScope:(TMScope *)scope {
  if (!_currentSymbol && [[TMPreference preferenceValueForKey:TMPreferenceShowInSymbolListKey qualifiedIdentifier:scope.qualifiedIdentifier] boolValue]) {
    _currentSymbol = scope;
  }
}

- (void)_endScope:(TMScope *)scope {
  if (scope == _currentSymbol) {
    [_symbolList addObject:_currentSymbol];
    _currentSymbol = nil;
  }
}

- (void)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope {
  [_attributedContent addAttribute:_qualifiedIdentifierAttributeName value:scope.qualifiedIdentifier range:tokenRange];
}

@end
