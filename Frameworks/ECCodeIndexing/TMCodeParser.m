//
//  TMCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeParser.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"

@interface TMCodeParser ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (atomic, strong) NSURL *fileURL;
@property (nonatomic, strong) TMSyntax *syntax;
- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPatterns:(NSArray *)patterns scopesStack:(NSMutableArray *)scopesStack usingBlock:(void(^)(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isExitingScope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop))block;
- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern scopesStack:(NSMutableArray *)scopesStack usingBlock:(void(^)(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop))block;
@end

@implementation TMCodeParser

@synthesize fileURL = _fileURL;
@synthesize syntax = _syntax;

- (ECCodeIndex *)index
{
    // TMCodeUnits do not require indexes at the moment
    return nil;
}

- (NSString *)language
{
    return self.syntax.name;
}

- (id)initWithFileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax
{
    ECASSERT([fileURL isFileURL]);
    ECASSERT(syntax);
    self = [super init];
    if (!self)
        return nil;
    self.fileURL = fileURL;
    self.syntax = syntax;
    return self;
}

- (void)enumerateScopesInRange:(NSRange)range usingBlock:(void (^)(NSString *, NSRange, BOOL, BOOL, BOOL, NSArray *, BOOL *, BOOL *))block
{
    __block NSString *string = nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        string = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL];
    }];
    NSMutableArray *scopesStack = [NSMutableArray array];
    __block BOOL firstMatch = YES;
    [self _enumerateScopesInString:string range:NSMakeRange(0, [string length]) withPatterns:self.syntax.patterns scopesStack:scopesStack usingBlock:^(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isExitingScope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop) {
        ECASSERT(beginMatch && pattern && scope && skipChildren && stop);
        ECASSERT(isLeafScope || endMatch);
        ECASSERT(!isExitingScope || !isLeafScope);
        if ((isLeafScope || !isExitingScope) && (NSMaxRange(beginMatch.range) < range.location || beginMatch.range.location >= NSMaxRange(range)))
            return;
        if (isExitingScope && (NSMaxRange(endMatch.range) < range.location || endMatch.range.location >= NSMaxRange(range)))
            return;
        if (firstMatch)
        {
            skippedScopes = YES;
            firstMatch = NO;
        }
        if (!isLeafScope && !isExitingScope)
        {
            block(scope, NSMakeRange(beginMatch.range.location, NSMaxRange(endMatch.range) - beginMatch.range.location), isExitingScope, isLeafScope, skippedScopes, [scopesStack copy], skipChildren, stop);
            if (*stop || *skipChildren)
                return;
        }
        NSDictionary *captures = isLeafScope ? pattern.captures : (isExitingScope ? pattern.endCaptures : pattern.beginCaptures);
        NSString *mainCapture = [captures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
        NSTextCheckingResult *capturesMatch = isExitingScope ? endMatch : beginMatch;
        NSUInteger numMatchRanges = capturesMatch.numberOfRanges;
        NSUInteger numCaptures = MIN([pattern.captures count] - (mainCapture ? 1 : 0), numMatchRanges);
        if (!mainCapture && numCaptures)
            mainCapture = pattern.name;
        BOOL skipCaptures = NO;
        if (mainCapture && capturesMatch.range.location >= range.location)
        {
            [scopesStack addObject:mainCapture];
            block(mainCapture, capturesMatch.range, NO, numCaptures ? YES : NO, NO, [scopesStack copy], &skipCaptures, stop);
            if (*stop)
                return;
        }
        if (!skipCaptures)
        {
            for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
            {
                NSRange currentMatchRange = [capturesMatch rangeAtIndex:currentMatchRangeIndex];
                if (NSMaxRange(currentMatchRange) < range.location)
                    continue;
                if (currentMatchRange.location >= NSMaxRange(range))
                    break;
                NSString *currentCapture = [captures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                if (!currentCapture)
                    continue;
                [scopesStack addObject:currentCapture];
                block(currentCapture, currentMatchRange, NO, YES, NO, [scopesStack copy], &skipCaptures, stop);
                [scopesStack removeLastObject];
                if (*stop)
                    return;
            }
        }
        if (mainCapture && numCaptures && NSMaxRange(capturesMatch.range) <= NSMaxRange(range))
        {
            block(mainCapture, capturesMatch.range, YES, YES, NO, [scopesStack copy], &skipCaptures, stop);
            [scopesStack removeLastObject];
            if (*stop)
                return;
        }
        if (!isLeafScope && isExitingScope)
        {
            block(scope, NSMakeRange(beginMatch.range.location, NSMaxRange(endMatch.range) - beginMatch.range.location), isExitingScope, isLeafScope, skippedScopes, [scopesStack copy], skipChildren, stop);
            if (*stop || *skipChildren)
                return;
        }
    }];
}

#pragma mark - NSFileCoordination

- (NSURL *)presentedItemURL
{
    return self.fileURL;
}

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL
{
    return [NSSet setWithObject:@"fileURL"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    if (!_presentedItemOperationQueue)
    {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
        _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    self.fileURL = newURL;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    self.fileURL = nil;
}

#pragma mark - Private methods

- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPatterns:(NSArray *)patterns scopesStack:(NSMutableArray *)scopesStack usingBlock:(void (^)(NSTextCheckingResult *, NSTextCheckingResult *, TMPattern *, NSString *, BOOL, BOOL, BOOL, BOOL *, BOOL *))block
{
    NSRange currentRange = range;
    for (;;)
    {
        __block NSTextCheckingResult *firstScopeBeginMatch = nil;
        __block NSTextCheckingResult *firstScopeEndMatch = nil;
        __block TMPattern *firstScopePattern = nil;
        __block NSString *firstScope = nil;
        __block BOOL firstScopeIsLeaf = NO;
        __block BOOL firstScopeSkippedScopes = NO;
        for (TMPattern *pattern in patterns)
            [self _enumerateScopesInString:string range:currentRange withPattern:pattern scopesStack:scopesStack usingBlock:^(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop) {
                ECASSERT(beginMatch && pattern && scope && skipChildren && stop);
                ECASSERT(isLeafScope || endMatch);
                if (firstScopeBeginMatch)
                {
                    NSRange beginRange = beginMatch.range;
                    NSRange firstRange = firstScopeBeginMatch.range;
                    if (beginRange.location > firstRange.location || (beginRange.location == firstRange.location && beginRange.length < firstRange.length))
                        return;
                }
                firstScopeBeginMatch = beginMatch;
                firstScopeEndMatch = endMatch;
                firstScopePattern = pattern;
                firstScope = scope;
                firstScopeIsLeaf = isLeafScope;
                firstScopeSkippedScopes = skippedScopes;
            }];
        if (!firstScopeBeginMatch)
            break;
        
        [scopesStack addObject:firstScope];
        BOOL stop = NO;
        BOOL skipChildren = NO;
        block(firstScopeBeginMatch, firstScopeEndMatch, firstScopePattern, firstScope, NO, firstScopeIsLeaf, firstScopeSkippedScopes, &skipChildren, &stop);
        if (stop)
            break;
        if (!firstScopeIsLeaf)
        {
            if (!skipChildren && [firstScopePattern.patterns count])
            {
                NSUInteger childrenRangeLocation = NSMaxRange(firstScopeBeginMatch.range);
                [self _enumerateScopesInString:string range:NSMakeRange(childrenRangeLocation, firstScopeEndMatch.range.location - childrenRangeLocation) withPatterns:firstScopePattern.patterns scopesStack:scopesStack usingBlock:block];
            }
            block(firstScopeBeginMatch, firstScopeEndMatch, firstScopePattern, firstScope, YES, NO, firstScopeSkippedScopes, &skipChildren, &stop);
        }
        [scopesStack removeLastObject];
        if (stop)
            break;        
        NSUInteger offset = (firstScopeIsLeaf ? NSMaxRange(firstScopeBeginMatch.range) : NSMaxRange(firstScopeEndMatch.range)) - currentRange.location;
        currentRange.location += offset;
        currentRange.length -= offset;
    }
}

- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern scopesStack:(NSMutableArray *)scopesStack usingBlock:(void (^)(NSTextCheckingResult *, NSTextCheckingResult *, TMPattern *, NSString *, BOOL, BOOL, BOOL *, BOOL *))block
{
    ECASSERT(pattern.include || pattern.match || pattern.begin || pattern.patterns);
    if (pattern.include)
    {
        
    }
    else if (pattern.match)
    {
        
    }
    else if (pattern.begin)
    {
        
    }
    else
    {
        [self _enumerateScopesInString:string range:range withPatterns:pattern.patterns scopesStack:scopesStack usingBlock:^(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isExitingScope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop) {
            block(beginMatch, endMatch, pattern, scope, isLeafScope, skippedScopes, skipChildren, stop);
        }];
    }
}

@end
