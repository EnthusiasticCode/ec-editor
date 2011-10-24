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
@property (nonatomic, strong) TMCodeIndex *index;
@property (atomic, strong) NSURL *fileURL;
@property (nonatomic, strong) TMSyntax *syntax;
// Returns an array containing the first begin match at index 0 and the first end match at index 1 if the first matching pattern has an end matchv
// The patterns array may only contain matching patterns, not include patterns
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
@end

@implementation TMCodeParser

@synthesize index = _index;
@synthesize fileURL = _fileURL;
@synthesize syntax = _syntax;

- (NSString *)language
{
    return self.syntax.name;
}

- (id)initWithIndex:(TMCodeIndex *)index fileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax
{
    ECASSERT(index);
    ECASSERT([fileURL isFileURL]);
    ECASSERT(syntax);
    self = [super init];
    if (!self)
        return nil;
    self.index = index;
    self.fileURL = fileURL;
    self.syntax = syntax;
    return self;
}

- (void)visitScopesInRange:(NSRange)range usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (!visitorBlock)
        return;
    __block NSString *string = nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        string = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL];
        ECASSERT(NSMaxRange(range) <= [string length]);
        NSMutableArray *scopesStack = [NSMutableArray arrayWithObject:self.syntax.scope];
        [self _visitScopesInString:string range:range withPattern:self.syntax.pattern previousScopeStack:scopesStack usingVisitor:visitorBlock];
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

#define STOP_IF_VISITORRESULT_EQUALS_BREAK \
do\
{\
if (visitorResult == ECCodeVisitorResultBreak)\
{\
*stop = YES;\
return;\
}\
}\
while(NO);


- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    ECASSERT([string length] && NSMaxRange(range) <= [string length] && pattern && previousScopeStack && visitorBlock);
    ECASSERT(pattern.include || pattern.match || pattern.begin || pattern.patterns);
    if (pattern.include)
        [self _visitScopesInString:string range:range withIncludePattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.match)
        [self _visitScopesInString:string range:range withMatchPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.begin)
        [self _visitScopesInString:string range:range withSpanPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else
        [self _visitScopesInString:string range:range withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    unichar firstCharacter = [pattern.include characterAtIndex:0];
    if (firstCharacter == '$')
    {
        [self _visitScopesInString:string range:range withPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else if (firstCharacter == '#')
    {
        [self _visitScopesInString:string range:range withPattern:[self.syntax.repository objectForKey:[pattern.include substringFromIndex:1]] previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else
    {
        [previousScopeStack addObject:pattern.include];
        [[self.index codeUnitImplementingProtocol:@protocol(ECCodeParser) withFile:self.fileURL language:nil scope:pattern.include] visitScopesInRange:range usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isExitingScope, BOOL isLeafScope, NSArray *scopesStack) {
            return visitorBlock(scope, scopeRange, isExitingScope, isLeafScope, [previousScopeStack arrayByAddingObjectsFromArray:scopesStack]);
        }];
        [previousScopeStack removeObject:pattern.include];
    }
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    if (pattern.captures)
        [pattern.match enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            ECASSERT(result.numberOfRanges > 1);
            ECCodeVisitorResult visitorResult = visitorBlock(pattern.name, result.range, NO, NO, [previousScopeStack copy]);
            STOP_IF_VISITORRESULT_EQUALS_BREAK;
            if (visitorResult == ECCodeVisitorResultRecurse)
            {
                NSUInteger numMatchRanges = result.numberOfRanges;
                for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                {
                    NSRange currentMatchRange = [result rangeAtIndex:currentMatchRangeIndex];
                    NSString *currentCapture = [pattern.captures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                    if (!currentCapture)
                        continue;
                    [previousScopeStack addObject:currentCapture];
                    visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
                    STOP_IF_VISITORRESULT_EQUALS_BREAK;
                    [previousScopeStack removeLastObject];
                }
            }
            visitorResult = visitorBlock(pattern.name, result.range, NO, YES, [previousScopeStack copy]);
            STOP_IF_VISITORRESULT_EQUALS_BREAK;
            [previousScopeStack removeLastObject];
        }];
    else
        [pattern.match enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            ECASSERT(pattern.name);
            ECCodeVisitorResult visitorResult = visitorBlock(pattern.name, result.range, YES, NO, [previousScopeStack copy]);
            STOP_IF_VISITORRESULT_EQUALS_BREAK;
        }];
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    [pattern.begin enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSTextCheckingResult *endMatch = [pattern.end firstMatchInString:string options:0 range:NSMakeRange(range.location + result.range.length, range.length - result.range.length)];
        NSUInteger spanStart = result.range.location;
        NSUInteger spanEnd = endMatch ? NSMaxRange(endMatch.range) : NSMaxRange(range) - spanStart;
        NSUInteger childScopesStart = NSMaxRange(result.range);
        NSUInteger childScopesEnd = endMatch ? endMatch.range.location : NSMaxRange(range) - childScopesStart;
        NSRange spanRange = NSMakeRange(spanStart, spanEnd - spanStart);
        NSRange childScopesRange = NSMakeRange(childScopesStart, childScopesEnd - childScopesStart);
        ECCodeVisitorResult visitorResult = ECCodeVisitorResultRecurse;
        if (pattern.name)
            visitorResult = visitorBlock(pattern.name, spanRange, NO, NO, [previousScopeStack copy]);
        STOP_IF_VISITORRESULT_EQUALS_BREAK;
        if (visitorResult == ECCodeVisitorResultRecurse)
        {
            if (pattern.beginCaptures)
            {
                NSString *mainCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
                if (mainCapture)
                {
                    [previousScopeStack addObject:mainCapture];
                    visitorResult = visitorBlock(mainCapture, result.range, NO, NO, [previousScopeStack copy]);
                }
                STOP_IF_VISITORRESULT_EQUALS_BREAK;
                if (visitorResult == ECCodeVisitorResultRecurse)
                {
                    NSUInteger numMatchRanges = result.numberOfRanges;
                    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                    {
                        NSRange currentMatchRange = [result rangeAtIndex:currentMatchRangeIndex];
                        NSString *currentCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                        if (!currentCapture)
                            continue;
                        [previousScopeStack addObject:currentCapture];
                        visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        STOP_IF_VISITORRESULT_EQUALS_BREAK;
                        [previousScopeStack removeLastObject];
                    }
                }
                if (mainCapture)
                {
                    visitorResult = visitorBlock(mainCapture, result.range, NO, YES, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                }
                STOP_IF_VISITORRESULT_EQUALS_BREAK;
            }
            [self _visitScopesInString:string range:childScopesRange withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
            if (pattern.endCaptures && endMatch)
            {
                NSString *mainCapture = [pattern.endCaptures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
                if (mainCapture)
                {
                    [previousScopeStack addObject:mainCapture];
                    visitorResult = visitorBlock(mainCapture, endMatch.range, NO, NO, [previousScopeStack copy]);
                }
                STOP_IF_VISITORRESULT_EQUALS_BREAK;
                if (visitorResult == ECCodeVisitorResultRecurse)
                {
                    NSUInteger numMatchRanges = endMatch.numberOfRanges;
                    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                    {
                        NSRange currentMatchRange = [endMatch rangeAtIndex:currentMatchRangeIndex];
                        NSString *currentCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                        if (!currentCapture)
                            continue;
                        [previousScopeStack addObject:currentCapture];
                        visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        STOP_IF_VISITORRESULT_EQUALS_BREAK;
                        [previousScopeStack removeLastObject];
                    }
                }
                if (mainCapture)
                {
                    visitorResult = visitorBlock(mainCapture, endMatch.range, NO, YES, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                }
                STOP_IF_VISITORRESULT_EQUALS_BREAK;
            }
        }
        if (pattern.name)
            visitorResult = visitorBlock(pattern.name, spanRange, NO, YES, [previousScopeStack copy]);
        STOP_IF_VISITORRESULT_EQUALS_BREAK;
    }];
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    NSRange currentRange = range;
    for (;;)
    {
        __block NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        __block TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in pattern.patterns)
            [self _visitScopesInString:string range:currentRange withPattern:childPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
                if (scopeRange.location < firstMatchRange.location || (scopeRange.location == firstMatchRange.location && scopeRange.length > firstMatchRange.length))
                {
                    firstMatchRange = scopeRange;
                    firstMatchPattern = childPattern;
                }
                return ECCodeVisitorResultBreak;
            }];
        if (!firstMatchPattern)
            break;
        __block NSUInteger stackDepth = 0;
        __block ECCodeVisitorResult visitorResult = ECCodeVisitorResultRecurse;
        [self _visitScopesInString:string range:currentRange withPattern:firstMatchPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
            visitorResult = visitorBlock(scope, scopeRange, isLeafScope, isExitingScope, scopesStack);
            if (!isLeafScope)
                if (isExitingScope)
                    --stackDepth;
                else
                    ++stackDepth;
            if (!stackDepth)
                return ECCodeVisitorResultBreak;
            return visitorResult;
        }];
        if (visitorResult == ECCodeVisitorResultBreak)
            break;
        NSUInteger offset = NSMaxRange(firstMatchRange) - currentRange.location;
        currentRange.location += offset;
        currentRange.length -= offset;
    }
}

#undef STOP_IF_VISITORRESULT_EQUALS_BREAK

@end
