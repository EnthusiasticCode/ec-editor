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
- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern scopeStack:(NSMutableArray *)scopesStack usingBlock:(void(^)(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isExitingScope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop))block;
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
    [self _enumerateScopesInString:string range:NSMakeRange(0, [string length]) withPattern:self.syntax.pattern scopeStack:scopesStack usingBlock:^(NSTextCheckingResult *beginMatch, NSTextCheckingResult *endMatch, TMPattern *pattern, NSString *scope, BOOL isExitingScope, BOOL isLeafScope, BOOL skippedScopes, BOOL *skipChildren, BOOL *stop) {
        ECASSERT(beginMatch);
        ECASSERT(pattern);
        ECASSERT(skipChildren);
        ECASSERT(stop);
        if (!endMatch && (NSMaxRange(beginMatch.range) < range.location || beginMatch.range.location > NSMaxRange(range)))
            return;
        if (endMatch && (NSMaxRange(endMatch.range) < range.location || beginMatch.range.location > NSMaxRange(range)))
            return;
        if (firstMatch)
        {
            skippedScopes = YES;
            firstMatch = NO;
        }
        if (endMatch && !isExitingScope)
        {
            block(scope, NSMakeRange(beginMatch.range.location, NSMaxRange(endMatch.range) - beginMatch.range.location), isExitingScope, isLeafScope, skippedScopes, [scopesStack copy], skipChildren, stop);
            if (*stop || *skipChildren)
                return;
        }
        if (![pattern.captures count])
            return;
        if ((isExitingScope && !endMatch) || (!isExitingScope && !beginMatch))
            return;
        NSString *mainCapture = [pattern.captures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
        NSTextCheckingResult *capturesMatch = isExitingScope ? endMatch : beginMatch;
        NSUInteger numMatchRanges = capturesMatch.numberOfRanges;
        NSUInteger numCaptures = MIN([pattern.captures count] - (mainCapture ? 1 : 0), numMatchRanges);
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
                if (currentMatchRange.location > NSMaxRange(range))
                    break;
                NSString *currentCapture = [pattern.captures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                if (!currentCapture)
                    continue;
                [scopesStack addObject:currentCapture];
                block(currentCapture, currentMatchRange, NO, YES, NO, [scopesStack copy], &skipCaptures, stop);
                [scopesStack removeLastObject];
                if (*stop)
                    return;
            }
        }
        if (mainCapture && NSMaxRange(capturesMatch.range) <= NSMaxRange(range))
        {
            block(mainCapture, capturesMatch.range, YES, numCaptures ? YES : NO, NO, [scopesStack copy], &skipCaptures, stop);
            [scopesStack removeLastObject];
            if (*stop)
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

- (void)_enumerateScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern scopeStack:(NSMutableArray *)scopesStack usingBlock:(void (^)(NSTextCheckingResult *, NSTextCheckingResult *, TMPattern *, NSString *, BOOL, BOOL, BOOL, BOOL *, BOOL *))block
{
    
    /*
    NSRange currentRange = range;
    NSTextCheckingResult *bestMatchResult = nil;
    TMPattern *bestMatchPattern = nil;
    do
    {
        for (TMPattern *pattern in self.syntax.patterns)
        {
            NSTextCheckingResult *matchResult = [pattern firstMatchInString:string options:0 range:currentRange];
            if (bestMatchResult)
                if (!matchResult || matchResult.range.location > bestMatchResult.range.location || (matchResult.range.location == bestMatchResult.range.location && matchResult.range.length < bestMatchResult.range.length))
                    continue;
            bestMatchResult = matchResult;
            bestMatchPattern = pattern;
        }
        if (!bestMatchResult)
            break;
        [scopeStack addObject:bestMatchPattern.name];
        BOOL stop = NO;
        BOOL skipChildren = NO;
        block([scopeStack copy], bestMatchResult.range, ECCodeScopeEnumerationStackChangeContinue, &skipChildren, &stop);
        if (stop)
            break;
        [scopeStack removeLastObject];
        NSUInteger offset = NSMaxRange(bestMatchResult.range) - currentRange.location;
        currentRange.location += offset;
        currentRange.length -= offset;
        bestMatchResult = nil;
    }
    while (bestMatchResult);
     */
}

@end
