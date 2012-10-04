//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem_Internal.h"
#import "RACEchoSubject.h"

static RACScheduler *_fileSystemScheduler;
static NSMutableDictionary *_itemCache;

@implementation FileSystemItem

+ (void)initialize {
  if (self != [FileSystemItem class]) {
    return;
  }
  _itemCache = [NSMutableDictionary dictionary];
}

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

+ (instancetype)cachedItemWithURL:(NSURL *)url {
  ASSERT_NOT_MAIN_QUEUE();
  return [_itemCache objectForKey:url];
}

+ (void)cacheItem:(FileSystemItem *)item {
  ASSERT_NOT_MAIN_QUEUE();
  ASSERT(![_itemCache objectForKey:item.itemURLBacking]);
  [_itemCache setObject:item forKey:item.itemURLBacking];
}

+ (id<RACSubscribable>)readItemAtURL:(NSURL *)url {
  if (!url) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [self coordinateSubscribable:[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
    ASSERT_NOT_MAIN_QUEUE();
    FileSystemItem *item = [_itemCache objectForKey:url];
    if (!item) {
      item = [[self alloc] initByReadingItemAtURL:url];
      if (item) {
        [self cacheItem:item];
      }
    }
    if (!item) {
      [subscriber sendError:[[NSError alloc] init]];
      return nil;
    }
    ASSERT([item.itemURLBacking isEqual:url]);
    [subscriber sendNext:item];
    [subscriber sendCompleted];
    return nil;
  }]];
}

- (id<RACSubscribable>)internalItemURL {
  return RACAble(self.itemURLBacking);
}

- (id<RACSubscribable>)itemURL {
  return [[self class] coordinateSubscribable:[self internalItemURL]];
}

- (instancetype)initByReadingItemAtURL:(NSURL *)url {
  ASSERT(url);
  ASSERT_NOT_MAIN_QUEUE();
  self = [super init];
  if (!self) {
    return nil;
  }
  self.itemURLBacking = url;
  NSString *itemType = nil;
  [url getResourceValue:&itemType forKey:NSURLFileResourceTypeKey error:NULL];
  if (!itemType) {
    return nil;
  }
  self.itemTypeBacking = itemType;
  return self;
}

#pragma mark - Internal state backing and echoes

@synthesize contentEcho = _contentEcho;

- (RACEchoSubject *)contentEcho {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_contentEcho) {
    _contentEcho = [RACEchoSubject replaySubjectWithCapacity:1];
    [_contentEcho sendNext:self.contentBacking];
    RAC(self.contentBacking) = _contentEcho;
  }
  return _contentEcho;
}

@synthesize extendedAttributesBacking = _extendedAttributesBacking;

- (NSMutableDictionary *)extendedAttributesBacking {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_extendedAttributesBacking) {
    _extendedAttributesBacking = [NSMutableDictionary dictionary];
  }
  return _extendedAttributesBacking;
}

@synthesize extendedAttributesEchoes = _extendedAttributesEchoes;

- (NSMutableDictionary *)extendedAttributesEchoes {
  ASSERT_NOT_MAIN_QUEUE();
  if (!_extendedAttributesEchoes) {
    _extendedAttributesEchoes = [NSMutableDictionary dictionary];
  }
  return _extendedAttributesEchoes;
}

@end
