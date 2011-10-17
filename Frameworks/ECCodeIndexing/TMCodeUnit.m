//
//  TMCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeUnit.h"
#import "TMBundle.h"

@interface TMCodeUnit ()
{
    NSOperationQueue *_presentedItemOperationQueue;
}
@property (atomic, strong) NSURL *fileURL;
@property (nonatomic, strong) TMBundle *bundle;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) TMSyntax *syntax;
@end

@implementation TMCodeUnit

@synthesize fileURL = _fileURL;
@synthesize bundle = _bundle;
@synthesize language = _language;
@synthesize syntax = _syntax;

- (ECCodeIndex *)index
{
    // TMCodeUnits do not require indexes at the moment
    return nil;
}

- (id)initWithFileURL:(NSURL *)fileURL bundleName:(NSString *)bundleName language:(NSString *)language
{
    ECASSERT([fileURL isFileURL]);
    ECASSERT(bundleName);
    self = [super init];
    if (!self)
        return nil;
    TMBundle *bundle = [TMBundle bundleWithName:bundleName];
    if (!language)
        language = bundleName;
    TMSyntax *syntax = [bundle.syntaxes objectForKey:language];
    if (!syntax)
        return nil;
    self.fileURL = fileURL;
    self.bundle = bundle;
    self.language = language;
    self.syntax = syntax;
    return self;
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
