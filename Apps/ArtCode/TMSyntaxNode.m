//
//  TMSyntaxNode.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntaxNode.h"
#import "TMBundle.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "ACProjectFile.h"

static NSString * const _syntaxDirectory = @"Syntaxes";

static NSString * const _scopeIdentifierKey = @"scopeName";
static NSString * const _fileTypesKey = @"fileTypes";
static NSString * const _firstLineMatchKey = @"firstLineMatch";
static NSString * const _foldingStartMarkerKey = @"foldingStartMarker";
static NSString * const _foldingStopMarkerKey = @"foldingStopMarker";
static NSString * const _matchKey = @"match";
static NSString * const _beginKey = @"begin";
static NSString * const _endKey = @"end";
static NSString * const _nameKey = @"name";
static NSString * const _contentNameKey = @"contentName";
static NSString * const _capturesKey = @"captures";
static NSString * const _beginCapturesKey = @"beginCaptures";
static NSString * const _endCapturesKey = @"endCaptures";
static NSString * const _patternsKey = @"patterns";
static NSString * const _repositoryKey = @"repository";
static NSString * const _includeKey = @"include";

static NSMutableDictionary *_syntaxesWithIdentifier;
static NSMutableArray *_syntaxesWithoutIdentifier;

static dispatch_semaphore_t _includedNodesCachesLock;
static NSMutableDictionary *_includedNodesCaches;

@interface TMSyntaxNode ()

+ (TMSyntaxNode *)_syntaxWithPredicateBlock:(BOOL (^)(TMSyntaxNode *syntaxNode))predicateBlock;

- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax;

@end

@implementation TMSyntaxNode

@synthesize rootSyntax = _rootSyntax;
@synthesize identifier = _identifier;
@synthesize fileTypes = _fileTypes;
@synthesize firstLineMatch = _firstLineMatch;
@synthesize foldingStartMarker = _foldingStartMarker;
@synthesize foldingStopMarker = _foldingStopMarker;
@synthesize match = _match;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize name = _name;
@synthesize contentName = _contentName;
@synthesize captures = _captures;
@synthesize beginCaptures = _beginCaptures;
@synthesize endCaptures = _endCaptures;
@synthesize patterns = _patterns;
@synthesize repository = _repository;
@synthesize include = _include;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [TMSyntaxNode class]) {
    return;
  }
  // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
#if ! TEST
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
#endif
  
  _includedNodesCachesLock = dispatch_semaphore_create(1);
  _includedNodesCaches = NSMutableDictionary.alloc.init;
  
  _syntaxesWithIdentifier = NSMutableDictionary.alloc.init;
// TODO URI: figure out what the syntaxes without identifier are and possibly get rid of them or handle them differently
  _syntaxesWithoutIdentifier = NSMutableArray.alloc.init;
  NSFileManager *fileManager = NSFileManager.alloc.init;
  for (NSURL *bundleURL in [TMBundle bundleURLs]) {
    for (NSURL *syntaxURL in [fileManager contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:0 error:NULL]) {
      NSData *plistData = [NSData dataWithContentsOfURL:syntaxURL options:NSDataReadingUncached error:NULL];
      if (!plistData) {
        continue;
      }
      NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:NULL];
      if (!plist) {
        continue;
      }
      TMSyntaxNode *syntax = [[self alloc] _initWithDictionary:plist syntax:nil];
      if (!syntax) {
        continue;
      }
      if (syntax.identifier) {
        [_syntaxesWithIdentifier setObject:syntax forKey:syntax.identifier];
      } else {
        [_syntaxesWithoutIdentifier addObject:syntax];
      }
    }
  }
  _syntaxesWithIdentifier = [_syntaxesWithIdentifier copy];
}

- (NSUInteger)hash {
  if (_identifier) {
    return _identifier.hash;
  }
  else if (_include) {
    return _include.hash;
  }
  else {
    return _patterns.hash;
  }
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

#pragma mark - Public Methods

+ (TMSyntaxNode *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier {
  if (!scopeIdentifier) {
    return nil;
  }
  return [_syntaxesWithIdentifier objectForKey:scopeIdentifier];
}

+ (TMSyntaxNode *)syntaxForFileName:(NSString *)fileName {
  NSString *fileExtension = fileName.pathExtension;
  if (!fileExtension) {
    return nil;
  }
  return [self _syntaxWithPredicateBlock:^BOOL(TMSyntaxNode *syntax) {
    for (NSString *fileType in syntax.fileTypes) {
      if ([fileType isEqualToString:fileExtension]) {
        return YES;
      }
    }
    return NO;
  }];
}

+ (TMSyntaxNode *)syntaxForFirstLine:(NSString *)firstLine {
  if (!firstLine) {
    return nil;
  }
  return [self _syntaxWithPredicateBlock:^BOOL(TMSyntaxNode *syntax) {
    if (firstLine && [syntax.firstLineMatch search:firstLine]) {
      return YES;
    }
    return NO;
  }];
}

+ (TMSyntaxNode *)defaultSyntax {
  return [self syntaxWithScopeIdentifier:@"text.plain"];
}

- (NSString *)qualifiedIdentifier {
  return self.identifier;
}

- (NSArray *)includedNodesWithRootNode:(TMSyntaxNode *)rootNode
{
  ASSERT(!self.include); // This cannot be called on include nodes.
  dispatch_semaphore_wait(_includedNodesCachesLock, DISPATCH_TIME_FOREVER);
  NSMutableArray *includedNodes = [(NSMutableDictionary *)[_includedNodesCaches objectForKey:rootNode] objectForKey:self];
  dispatch_semaphore_signal(_includedNodesCachesLock);
  if (includedNodes)
    return includedNodes;
  if (!self.patterns)
    return nil;
  includedNodes = [NSMutableArray arrayWithArray:self.patterns];
  NSMutableSet *dereferencedNodes = [NSMutableSet set];
  NSMutableIndexSet *containerNodesIndexes = [NSMutableIndexSet indexSet];
  do
  {
    [containerNodesIndexes removeAllIndexes];
    [includedNodes enumerateObjectsUsingBlock:^(TMSyntaxNode *obj, NSUInteger idx, BOOL *stop) {
      if ([obj match] || [obj begin])
        return;
      [containerNodesIndexes addIndex:idx];
    }];
    __block NSUInteger offset = 0;
    [containerNodesIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      TMSyntaxNode *containerNode = [includedNodes objectAtIndex:idx + offset];
      [includedNodes removeObjectAtIndex:idx + offset];
      if ([dereferencedNodes containsObject:containerNode])
        return;
      ASSERT(containerNode.include || containerNode.patterns);
      ASSERT(!containerNode.include || !containerNode.patterns);
      if (containerNode.include)
      {
        unichar firstCharacter = [containerNode.include characterAtIndex:0];
        if (firstCharacter == '#')
        {
          [includedNodes insertObject:[[containerNode rootSyntax].repository objectForKey:[containerNode.include substringFromIndex:1]] atIndex:idx + offset];
        }
        else
        {
          ASSERT(firstCharacter != '$' || [containerNode.include isEqualToString:@"$base"] || [containerNode.include isEqualToString:@"$self"]);
          TMSyntaxNode *includedSyntax = nil;
          if ([containerNode.include isEqualToString:@"$base"])
            includedSyntax = rootNode;
          else if ([containerNode.include isEqualToString:@"$self"])
            includedSyntax = [containerNode rootSyntax];
          else
            includedSyntax = [TMSyntaxNode syntaxWithScopeIdentifier:containerNode.include];
          [includedNodes addObject:includedSyntax];
        }
      }
      else
      {
        NSUInteger patternsCount = [containerNode.patterns count];
        ASSERT(patternsCount);
        [includedNodes insertObjects:containerNode.patterns atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx + offset, patternsCount)]];
        offset += patternsCount - 1;
      }
      [dereferencedNodes addObject:containerNode];
    }];
  }
  while ([containerNodesIndexes count]);
  dispatch_semaphore_wait(_includedNodesCachesLock, DISPATCH_TIME_FOREVER);
  NSMutableDictionary *includedNodesCache = [_includedNodesCaches objectForKey:rootNode];
  if (!includedNodesCache) {
    includedNodesCache = NSMutableDictionary.alloc.init;
  }
  [includedNodesCache setObject:includedNodes forKey:self];
  [_includedNodesCaches setObject:includedNodesCache forKey:rootNode];
  dispatch_semaphore_signal(_includedNodesCachesLock);
  return includedNodes;
}

#pragma mark - Private Methods

+ (TMSyntaxNode *)_syntaxWithPredicateBlock:(BOOL (^)(TMSyntaxNode *))predicateBlock {
  for (TMSyntaxNode *syntax in [_syntaxesWithIdentifier objectEnumerator]) {
    if (predicateBlock(syntax)) {
      return syntax;
    }
  }
  for (TMSyntaxNode *syntax in _syntaxesWithoutIdentifier) {
    if (predicateBlock(syntax)) {
      return syntax;
    }
  }
  return nil;
}


// TODO URI: handle errors more gracefully here

- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax {
  ASSERT(dictionary);
  self = [super init];
  if (!self) {
    return nil;
  }
  if (!syntax) {
    syntax = self;
  }
  [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id propertyValue, BOOL *outerStop) {
    if ([propertyKey isEqualToString:_scopeIdentifierKey]) {
      _identifier = propertyValue;
    } else if ([propertyKey isEqualToString:_fileTypesKey] ||
               [propertyKey isEqualToString:_endKey] ||
               [propertyKey isEqualToString:_nameKey] ||
               [propertyKey isEqualToString:_contentNameKey] ||
               [propertyKey isEqualToString:_capturesKey] ||
               [propertyKey isEqualToString:_beginCapturesKey] ||
               [propertyKey isEqualToString:_endCapturesKey] ||
               [propertyKey isEqualToString:_includeKey])
    {
      if (([propertyValue respondsToSelector:@selector(length)] && [propertyValue length]) || ([propertyValue respondsToSelector:@selector(count)] && [(NSArray *)propertyValue count]))
        [self setValue:propertyValue forKey:propertyKey];
    }
    else if ([propertyKey isEqualToString:_firstLineMatchKey] ||
             [propertyKey isEqualToString:_foldingStartMarkerKey] ||
             [propertyKey isEqualToString:_foldingStopMarkerKey] ||
             [propertyKey isEqualToString:_matchKey] ||
             [propertyKey isEqualToString:_beginKey])
    {
      if ([propertyValue length])
        [self setValue:[OnigRegexp compile:propertyValue options:OnigOptionCaptureGroup] forKey:propertyKey];
    }
    else if ([propertyKey isEqualToString:_patternsKey])
    {
      NSMutableArray *patterns = [[NSMutableArray alloc] init];
      for (NSDictionary *patternDictionary in propertyValue)
        [patterns addObject:[[[self class] alloc] _initWithDictionary:patternDictionary syntax:syntax]];
      if ([patterns count])
        [self setValue:[patterns copy] forKey:propertyKey];
    }
    else if ([propertyKey isEqualToString:_repositoryKey])
    {
      NSMutableDictionary *repository = [[NSMutableDictionary alloc] init];
      [propertyValue enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *innerStop) {
        [repository setObject:[[[self class] alloc] _initWithDictionary:obj syntax:syntax] forKey:key];
      }];
      if ([repository count])
        [self setValue:[repository copy] forKey:propertyKey];
    }
  }];
  _rootSyntax = syntax;
  if (_captures && !_beginCaptures) {
    _beginCaptures = _captures;
  }
  if (_captures && !_endCaptures) {
    _endCaptures = _captures;
  }
  if (_name && !_identifier && _rootSyntax) {
    _identifier = _name;
  }
  return self;
}

@end

