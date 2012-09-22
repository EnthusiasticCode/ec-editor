//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit.h"
#import "TMIndex.h"
#import "TMScope+Internal.h"
#import "TMSyntaxNode.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "NSString+CStringCaching.h"
#import "NSIndexSet+StringRanges.h"
#import "TMPreference.h"
#import "DiffMatchPatch.h"
#import "TMSymbol.h"


static NSString * const _qualifiedIdentifierAttributeName = @"TMUnitQualifiedIdentifierAttributeName";

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;


@interface TMToken ()

@property (nonatomic, strong) NSString *qualifiedIdentifier;
@property (nonatomic) NSRange range;

@end

#pragma mark -

@interface Change : NSObject
{
  @package
  NSRange oldRange;
  NSRange newRange;
}
@end

#pragma mark - Helper Functions

void _generateScopesWithCaptures(NSDictionary *dictionary, OnigResult *result, TMScopeType type, NSUInteger offset, TMScope *parentScope, void(^scopeStartHandler)(TMScope *scope), void(^scopeEndHandler)(TMScope *scope)) {
  ASSERT(type == TMScopeTypeMatch || type == TMScopeTypeBegin || type == TMScopeTypeEnd);
  ASSERT(result && parentScope && scopeStartHandler && scopeEndHandler);
  
  if (!dictionary) {
    return;
  }
  
  TMScope *capturesScope = parentScope;
  if (type != TMScopeTypeMatch) {
    capturesScope = [parentScope newChildScopeWithIdentifier:[(NSDictionary *)[dictionary objectForKey:@"0"] objectForKey:_captureName] syntaxNode:nil location:[result bodyRange].location + offset type:type];
    scopeStartHandler(capturesScope);
    capturesScope.length = [result bodyRange].length;
  }
  NSMutableArray *capturesScopesStack = [NSMutableArray arrayWithObject:capturesScope];
  NSUInteger numMatchRanges = [result count];
  for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex) {
    NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
    // If the capture group wasn't found it's going to have location 0, length 0
    // It could be a false negative, but there's no good way to check for it
    if (!currentMatchRange.location && !currentMatchRange.length) {
      continue;
    }
    currentMatchRange.location += offset;
    NSString *currentCaptureName = [(NSDictionary *)[dictionary objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
    if (!currentCaptureName) {
      continue;
    }
    while (currentMatchRange.location < capturesScope.location || NSMaxRange(currentMatchRange) > capturesScope.location + capturesScope.length) {
      ASSERT([capturesScopesStack count]);
      scopeEndHandler(capturesScope);
      [capturesScopesStack removeLastObject];
      capturesScope = [capturesScopesStack lastObject];
    }
    TMScope *currentCaptureScope = [capturesScope newChildScopeWithIdentifier:currentCaptureName syntaxNode:nil location:currentMatchRange.location type:TMScopeTypeCapture];
    scopeStartHandler(currentCaptureScope);
    currentCaptureScope.length = currentMatchRange.length;
    [capturesScopesStack addObject:currentCaptureScope];
    capturesScope = currentCaptureScope;
  }
  TMScope *remainingScope = nil;
  while ((remainingScope = [capturesScopesStack lastObject])) {
    // If this is the last scope on the stack and it's a match scope, don't end it, it's going to be ended by the caller
    if ([capturesScopesStack count] == 1 && type == TMScopeTypeMatch) {
      break;
    }
    scopeEndHandler(remainingScope);
    [capturesScopesStack removeLastObject];
  }
}

void _generateScopesWithLine(NSString *line, NSRange lineRange, TMSyntaxNode *rootSyntax, NSMutableArray *scopeStack, void(^scopeStartHandler)(TMScope *scope), void(^scopeEndHandler)(TMScope *scope)) {
  ASSERT(line && scopeStack && scopeStartHandler && scopeEndHandler);
  
  line = [line stringByCachingCString];
  NSUInteger position = 0;
  
  // Check for a span scope with a missing content scope
  {
    TMScope *scope = [scopeStack lastObject];
    if (scope.type == TMScopeTypeSpan && !(scope.flags & TMScopeHasContentScope) && scope.syntaxNode.contentName) {
      TMScope *contentScope = [scope newChildScopeWithIdentifier:scope.syntaxNode.contentName syntaxNode:scope.syntaxNode location:lineRange.location type:TMScopeTypeContent];
      scopeStartHandler(contentScope);
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
    NSArray *patterns = [syntaxNode includedNodesWithRootNode:rootSyntax];
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
        scope.length = resultRange.location - scope.location;
        scopeEndHandler(scope);
        [scopeStack removeLastObject];
        scope = [scopeStack lastObject];
      }
      scope.length = NSMaxRange(resultRange) - scope.location;
      scope.flags |= TMScopeHasEnd;
      // Handle end captures
      if (syntaxNode.endCaptures) {
        _generateScopesWithCaptures(syntaxNode.endCaptures, endResult, TMScopeTypeEnd, lineRange.location, scope, scopeStartHandler, scopeEndHandler);
        scope.flags |= TMScopeHasEndScope;
      }
      // Remove remaining child scopes
#warning TODO: since the children are sorted this could be done better, also finding the index of the new end scope could be done on the insertion above
      [[scope.children rac_where:^BOOL(TMScope *childScope) {
        return childScope.location > resultRange.location;
      }] makeObjectsPerformSelector:@selector(removeFromParent)];
      scopeEndHandler(scope);
      ASSERT([scopeStack count]);
      [scopeStack removeLastObject];
      // We don't need to make sure position advances since we changed the stack
      // This could bite us if there's a begin and end regexp that match in the same position
      position = NSMaxRange([endResult bodyRange]);
    } else if (firstSyntaxNode.match) {
      // Handle a match pattern
      NSRange resultRange = [firstResult bodyRange];
      resultRange.location += lineRange.location;
      TMScope *matchScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.identifier syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeMatch];
      scopeStartHandler(matchScope);
      matchScope.length = resultRange.length;
      // Handle match pattern captures
      _generateScopesWithCaptures(firstSyntaxNode.captures, firstResult, TMScopeTypeMatch, lineRange.location, matchScope, scopeStartHandler, scopeEndHandler);
      scopeEndHandler(matchScope);
      // We need to make sure position increases, or it would loop forever with a 0 width match
      position = NSMaxRange([firstResult bodyRange]);
      if (!resultRange.length) {
        ++position;
      }
    } else if (firstSyntaxNode.begin) {
      // Handle a new span pattern
      NSRange resultRange = [firstResult bodyRange];
      resultRange.location += lineRange.location;
      TMScope *spanScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.identifier syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeSpan];
      scopeStartHandler(spanScope);
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
      // Handle begin captures
      if (firstSyntaxNode.beginCaptures) {
        _generateScopesWithCaptures(firstSyntaxNode.beginCaptures, firstResult, TMScopeTypeBegin, lineRange.location, spanScope, scopeStartHandler, scopeEndHandler);
        spanScope.flags |= TMScopeHasBeginScope;
      }
      [scopeStack addObject:spanScope];
      // Handle content name nested scope
      if (firstSyntaxNode.contentName) {
        TMScope *contentScope = [spanScope newChildScopeWithIdentifier:firstSyntaxNode.contentName syntaxNode:firstSyntaxNode location:NSMaxRange(resultRange) type:TMScopeTypeContent];
        scopeStartHandler(contentScope);
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
}

TMScope *_generateRootScopeWithContent(NSString *content, TMSyntaxNode *rootSyntax, NSString *previousContent, TMScope *rootScope, void(^scopeStartHandler)(TMScope *scope), void(^scopeEndHandler)(TMScope *scope), void(^scopeRemoveHandler)(TMScope *scope), void(^parseStartHandler)(NSArray *scopeStack, NSUInteger position), void(^parseEndHandler)(NSArray *scopeStack, NSUInteger position)) {
  ASSERT(content && rootSyntax && previousContent && scopeStartHandler && scopeEndHandler && scopeRemoveHandler && parseStartHandler && parseEndHandler);
  
  // Prepare and update the root scope
  if (!rootScope) {
    rootScope = [TMScope newRootScopeWithIdentifier:rootSyntax.identifier syntaxNode:rootSyntax];
  }
  rootScope.content = content;
  
  // Diff the last parsed content with the new one
  DiffMatchPatch *diffMatchPatch = [[DiffMatchPatch alloc] init];
  NSMutableArray *diffs = [diffMatchPatch diff_mainOfOldString:previousContent andNewString:content checkLines:YES deadline:1.0];
  
  // Convert the diff into a change set
  NSUInteger currentOffset = 0;
  Change *currentChange = [[Change alloc] init];
  currentChange->oldRange.location = NSNotFound;
  NSMutableArray *changes = [[NSMutableArray alloc] init];
  for (Diff *diff in diffs) {
    switch (diff.operation) {
      case DIFF_EQUAL:
      {
        if (currentChange->newRange.length || currentChange->oldRange.length) {
          [changes addObject:currentChange];
          currentChange = [[Change alloc] init];
          currentChange->oldRange.location = NSNotFound;
        }
        currentOffset += diff.text.length;
        break;
      }
      case DIFF_INSERT:
      {
        if (currentChange->oldRange.location == NSNotFound) {
          currentChange->oldRange.location = currentOffset;
          currentChange->newRange.location = currentOffset;
        }
        currentChange->newRange.length += diff.text.length;
        currentOffset += diff.text.length;
        break;
      }
      case DIFF_DELETE:
      {
        if (currentChange->oldRange.location == NSNotFound) {
          currentChange->oldRange.location = currentOffset;
          currentChange->newRange.location = currentOffset;
        }
        currentChange->oldRange.length += diff.text.length;
        break;
      }
    }
  }
  if (currentChange->newRange.length || currentChange->oldRange.length) {
    [changes addObject:currentChange];
  }
  
  // Process the changes
  NSMutableIndexSet *unparsedRanges = [[NSMutableIndexSet alloc] init];
  for (Change *change in changes) {
    NSRange oldRange = change->oldRange;
    NSRange newRange = change->newRange;
    ASSERT(oldRange.location == newRange.location);
    // Adjust the scope tree to account for the change
    [rootScope shiftByReplacingRange:oldRange withRange:newRange onRemove:scopeRemoveHandler];
    // Replace the ranges in the unparsed ranges, add a placeholder if the change was a deletion so we know the part right after the deletion needs to be reparsed
    [unparsedRanges replaceIndexesInRange:oldRange withIndexesInRange:newRange];
    if (!newRange.length) {
      [unparsedRanges addIndex:newRange.location];
    }
  }
  
  // If the unparsedRanges contains an index beyond the end of the content, it means there was a deletion around the end of the content, just add the index at the end of the content to force the reparse of the last line
  if ([unparsedRanges containsIndex:content.length]) {
    [unparsedRanges removeIndex:content.length];
    if (content.length) {
      [unparsedRanges addIndex:content.length - 1];
    }
  }
  
  // Loop the unparsed ranges
  NSMutableArray *scopeStack = nil;
  while (unparsedRanges.count) {
    NSRange unparsedRange = [unparsedRanges firstRange];
    // If we're past the end of the content we're done
    if (unparsedRange.location >= content.length) {
      break;
    }
    // Get the line ranges
    NSRange linesRange = [content lineRangeForRange:unparsedRange];
    // Check if we got a valid range, if we didn't, we're done parsing
    if (!linesRange.length || NSMaxRange(linesRange) == unparsedRange.location) {
      break;
    }
    
    // Setup the scope stack
    if (!scopeStack) {
      scopeStack = [rootScope scopeStackAtOffset:linesRange.location options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
      ASSERT(scopeStack && [scopeStack count]);
    }
    parseStartHandler(scopeStack.copy, linesRange.location);
    
    // Delete all scopes in the lines
    [rootScope removeChildScopesInRange:linesRange onRemove:scopeRemoveHandler];
    
    NSRange currentLineRange = [content lineRangeForRange:NSMakeRange(linesRange.location, 0)];
    while (currentLineRange.location < NSMaxRange(linesRange)) {
      NSString *line = [content substringWithRange:currentLineRange];
      _generateScopesWithLine(line, currentLineRange, rootSyntax, scopeStack, scopeStartHandler, scopeEndHandler);

      // Stretch all remaining scopes to cover to the end of the line
      for (TMScope *scope in scopeStack)
      {
        NSUInteger stretchedLength = NSMaxRange(currentLineRange) - scope.location;
        if (stretchedLength > scope.length) {
          scope.length = stretchedLength;
        }
      }
      
      // Advance to next line and check that we actually advance. It will get stuck here if the file ends without a newline.
      NSRange oldLineRange = currentLineRange;
      currentLineRange = [content lineRangeForRange:NSMakeRange(NSMaxRange(currentLineRange), 0)];
      if (currentLineRange.location == oldLineRange.location) {
        break;
      }
    }
    
    // Mark the line ranges as parsed
    [unparsedRanges removeIndexesInRange:linesRange];
    parseEndHandler(scopeStack.copy, NSMaxRange(linesRange));
    
    // Attempt to merge the scopes at the end of the unparsed range. If the merge is successful, reset the scope stack for the next unparsed range, otherwise add the end of the line to the unparsed ranges and continue from there
    if ([rootScope attemptMergeAtOffset:NSMaxRange(linesRange)]) {
      scopeStack = nil;
    } else {
      [unparsedRanges addIndex:NSMaxRange(linesRange)];
    }
  }
  return rootScope;
}

#pragma mark -

@implementation TMUnit {
  NSString *_previousContent;
  NSMutableAttributedString *_attributedContent;
  
  TMScope *_rootScope;
  NSMutableArray *_symbolList;
  
  RACSubject *_tokens;
}

@synthesize index = _index, syntax = _syntax, symbolList = _symbolList, tokens = _tokens;

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

- (NSArray *)symbolList {
  return [_symbolList copy];
}

- (id<RACSubscribable>)tokens {
  if (!_tokens) {
    _tokens = [RACSubject subject];
  }
  return _tokens;
}

- (id)initWithFileURL:(NSURL *)fileURL syntax:(TMSyntaxNode *)syntax index:(TMIndex *)index {
  ASSERT(fileURL && syntax);
  self = [super init];
  if (!self) {
    return nil;
  }
  
  _syntax = syntax;
  _symbolList = [[NSMutableArray alloc] init];
  _previousContent = @"";
  _attributedContent = [[NSMutableAttributedString alloc] init];
  
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

- (void)reparseWithUnsavedContent:(NSString *)content {
  if (content == _previousContent) {
    return;
  }
  
  content = content.copy;
  
  // Diff the last parsed content with the new one
  DiffMatchPatch *diffMatchPatch = [[DiffMatchPatch alloc] init];
  NSMutableArray *diffs = [diffMatchPatch diff_mainOfOldString:_previousContent andNewString:content checkLines:YES deadline:1.0];
  NSUInteger currentOffset = 0;
  for (Diff *diff in diffs) {
    switch (diff.operation) {
      case DIFF_EQUAL:
      {
        currentOffset += diff.text.length;
        break;
      }
      case DIFF_INSERT:
      {
        [_attributedContent replaceCharactersInRange:NSMakeRange(currentOffset, 0) withString:diff.text];
        currentOffset += diff.text.length;
        break;
      }
      case DIFF_DELETE:
      {
        [_attributedContent replaceCharactersInRange:NSMakeRange(currentOffset, diff.text.length) withString:@""];
        break;
      }
    }
  }

  RACSubject *tokens = nil;
  if (_tokens) {
    tokens = [RACSubject subject];
    [_tokens sendNext:tokens];
  }

  void (^handleTokenWithRangeAndQualifiedIdentifier)(NSRange, NSString *) = ^(NSRange range, NSString *qualifiedIdentifier) {
    if (!range.length) {
      return;
    }
    if (tokens) {
      TMToken *token = [[TMToken alloc] init];
      token.qualifiedIdentifier = qualifiedIdentifier;
      token.range = range;
      [tokens sendNext:token];
    }
    [_attributedContent addAttribute:_qualifiedIdentifierAttributeName value:qualifiedIdentifier range:range];
  };
  
  [self willChangeValueForKey:@"symbolList"];
  
  __block NSMutableArray *lastScopeStack = nil;
  __block NSUInteger lastTokenEnd = 0;
  
  _rootScope = _generateRootScopeWithContent(content, _syntax, _previousContent, _rootScope, ^(TMScope *scope) {
    // Handle tokens
    ASSERT([lastScopeStack count]);
    handleTokenWithRangeAndQualifiedIdentifier(NSMakeRange(lastTokenEnd, scope.location - lastTokenEnd), [(TMScope *)[lastScopeStack lastObject] qualifiedIdentifier]);
    [lastScopeStack addObject:scope];
    
    // Add the symbol to the symbol list if needed
    TMSymbol *symbol = scope.symbol;
    if (symbol) {
      NSUInteger insertionIndex = [_symbolList indexOfObject:symbol inSortedRange:NSMakeRange(0, [_symbolList count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(TMSymbol *symbol1, TMSymbol *symbol2) {
        if (symbol1.range.location < symbol2.range.location) {
          return NSOrderedAscending;
        } else if (symbol1.range.location > symbol2.range.location) {
          return NSOrderedDescending;
        } else {
          if (symbol1.range.length > symbol2.range.length) {
            return NSOrderedAscending;
          } else if (symbol1.range.length < symbol2.range.length) {
            return NSOrderedDescending;
          } else {
            return NSOrderedSame;
          }
        }
      }];
      [_symbolList insertObject:symbol atIndex:insertionIndex];
    }
  }, ^(TMScope *scope) {
    // Handle tokens
    ASSERT([lastScopeStack count]);
    handleTokenWithRangeAndQualifiedIdentifier(NSMakeRange(lastTokenEnd, scope.location + scope.length - lastTokenEnd), [(TMScope *)[lastScopeStack lastObject] qualifiedIdentifier]);
    [lastScopeStack removeLastObject];
  }, ^(TMScope *scope) {
    // Remove the symbol from the symbol list if needed
    TMSymbol *symbol = scope.symbol;
    if (symbol) {
      [_symbolList removeObject:symbol];
    }
  }, ^(NSArray *scopeStack, NSUInteger position) {
    lastTokenEnd = position;
    lastScopeStack = [NSMutableArray arrayWithArray:scopeStack];
  }, ^(NSArray *scopeStack, NSUInteger position) {
    ASSERT([lastScopeStack count]);
    handleTokenWithRangeAndQualifiedIdentifier(NSMakeRange(lastTokenEnd, position - lastTokenEnd), [(TMScope *)[lastScopeStack lastObject] qualifiedIdentifier]);
    lastScopeStack = nil;
  });

  [self didChangeValueForKey:@"symbolList"];
  [tokens sendCompleted];
  
  _previousContent = content;
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  [_rootScope performSelector:@selector(_checkConsistency)];
#pragma clang diagnostic pop
#endif
}

@end

#pragma mark -

@implementation TMToken
@synthesize qualifiedIdentifier, range;
@end

#pragma mark -

@implementation Change
@end
