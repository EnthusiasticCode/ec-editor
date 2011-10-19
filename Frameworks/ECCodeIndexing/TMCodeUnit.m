//
//  TMCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeUnit.h"
#import "TMBundle.h"
#import "TMSyntax.h"

@interface TMCodeUnit ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (atomic, strong) NSURL *fileURL;
@property (nonatomic, strong) TMSyntax *syntax;
@end

@implementation TMCodeUnit

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
    UNIMPLEMENTED_VOID();
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
