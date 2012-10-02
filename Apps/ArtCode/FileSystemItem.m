//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem_Internal.h"

static RACScheduler *_fileSystemScheduler;

@implementation FileSystemItem

+ (RACScheduler *)fileSystemScheduler {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.name = @"FileSystemItem file system queue";
    operationQueue.maxConcurrentOperationCount = 1;
    _fileSystemScheduler = [RACScheduler schedulerWithOperationQueue:operationQueue];
  });
  return _fileSystemScheduler;
}

+ (id<RACSubscribable>)coordinateSubscribable:(id<RACSubscribable>)subscribable {
  return [[subscribable subscribeOn:[self fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

+ (id<RACSubscribable>)readItemAtURL:(NSURL *)url {
  return [self coordinateSubscribable:[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
    ASSERT_NOT_MAIN_QUEUE();
    FileSystemItem *item = [[self alloc] initByReadingItemAtURL:url];
    if (item) {
      [subscriber sendNext:item];
      [subscriber sendCompleted];
    } else {
      [subscriber sendError:[[NSError alloc] init]];
    }
    return [RACDisposable disposableWithBlock:nil];
  }]];
}

- (id<RACSubscribable>)internalItemURL {
  return RACAble(self.itemURLBacking);
}

- (id<RACSubscribable>)itemURL {
  return [[self class] coordinateSubscribable:[self internalItemURL]];
}

- (instancetype)initByReadingItemAtURL:(NSURL *)url {
  ASSERT_NOT_MAIN_QUEUE();
  self = [super init];
  if (!self) {
    return nil;
  }
  if (!url) {
    return nil;
  }
  self.itemURLBacking = url;
  return self;
}

@end
