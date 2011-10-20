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

- (void)enumerateScopesInRange:(NSRange)range usingBlock:(void (^)(NSArray *, NSRange, ECCodeScopeEnumerationStackChange, BOOL *, BOOL *))block
{
    __block NSString *string = nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        string = [[NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL] substringWithRange:range];
    }];
    NSRange currentRange = NSMakeRange(0, range.length);
    NSMutableArray *scopeStack = [NSMutableArray array];
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
            continue;
        [scopeStack addObject:bestMatchPattern.name];
        BOOL stop = NO;
        BOOL skipChildren = NO;
        block([scopeStack copy], bestMatchResult.range, ECCodeScopeEnumerationStackChangeContinue, &skipChildren, &stop);
        if (stop)
            break;
        [scopeStack removeLastObject];
        currentRange.location = NSMaxRange(bestMatchResult.range);
        currentRange.length = [string length] - currentRange.location;
        bestMatchResult = nil;
    }
    while (bestMatchResult);
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

@end
