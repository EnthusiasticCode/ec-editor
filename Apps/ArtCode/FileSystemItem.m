//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
#import "RACPropertySyncSubject.h"
#import "NSString+ScoreForAbbreviation.h"


@interface FileSystemItem ()

// All filesystem operations must be done on this scheduler
+ (RACScheduler *)fileSystemScheduler;
+ (NSMutableDictionary *)itemCache;


@property (nonatomic, strong) RACReplaySubject *urlBacking;
@property (nonatomic, strong) RACReplaySubject *typeBacking;

@property (nonatomic, strong) RACPropertySyncSubject *stringContent;

@property (nonatomic, strong) NSMutableDictionary *extendedAttributes;

@end

@interface FileSystemItem (Directory_Private)

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock;
- (id<RACSubscribable>)internalChildren;
- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options;

@end

@implementation FileSystemItem

+ (RACScheduler *)fileSystemScheduler {
  static RACScheduler *fileSystemScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.name = @"FileSystemItem file system queue";
    operationQueue.maxConcurrentOperationCount = 1;
    fileSystemScheduler = [RACScheduler schedulerWithOperationQueue:operationQueue];
  });
  return fileSystemScheduler;
}

+ (NSMutableDictionary *)itemCache {
  ASSERT_NOT_MAIN_QUEUE();
  static NSMutableDictionary *itemCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    itemCache = [NSMutableDictionary dictionary];
  });
  return itemCache;
}

+ (id<RACSubscribable>)itemWithURL:(NSURL *)url {
  return [self readItemAtURL:url];
}

+ (id<RACSubscribable>)fileWithURL:(NSURL *)url {
  return [self readItemAtURL:url];
}

+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url {
  return [self readItemAtURL:url];
}

+ (id<RACSubscribable>)readItemAtURL:(NSURL *)url {
  if (!url) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
      ASSERT_NOT_MAIN_QUEUE();
      FileSystemItem *item = [[self itemCache] objectForKey:url];
      if (item) {
        ASSERT([[item.urlBacking first] isEqual:url]);
        [subscriber sendNext:item];
        [subscriber sendCompleted];
        return nil;
      }
      NSString *type = nil;
      if (![url getResourceValue:&type forKey:NSURLFileResourceTypeKey error:NULL]) {
        [subscriber sendError:[[NSError alloc] init]];
        return nil;
      }
      item = [[self alloc] init];
      item.urlBacking = [RACReplaySubject replaySubjectWithCapacity:1];
      [item.urlBacking sendNext:url];
      item.typeBacking = [RACReplaySubject replaySubjectWithCapacity:1];
      [item.typeBacking sendNext:type];
      if (type == NSURLFileResourceTypeRegular) {
        item.stringContent = [RACPropertySyncSubject subject];
        NSError *error;
        [item.stringContent sendNext:[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error]];
        if (error) {
          [subscriber sendError:error];
          return nil;
        }
      }
      item.extendedAttributes = [NSMutableDictionary dictionary];
      [[self itemCache] setObject:item forKey:url];
      [subscriber sendNext:item];
      [subscriber sendCompleted];
      return nil;
    }];
  }] subscribeOn:[self fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)url {
  return [self.urlBacking deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)type {
  return [self.typeBacking deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)save {
  
}

@end

@implementation FileSystemItem (Directory)

- (id<RACSubscribable>)children {
  return [[[self internalChildren] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [[[self internalChildrenWithOptions:options] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[RACSubscribable combineLatest:@[[self internalChildren], abbreviationSubscribable] reduce:[[self class] filterAndSortByAbbreviationBlock]] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[RACSubscribable combineLatest:@[[self internalChildrenWithOptions:options], abbreviationSubscribable] reduce:[[self class] filterAndSortByAbbreviationBlock]] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

@end

@implementation FileSystemItem (FileManagement)

- (id<RACSubscribable>)moveTo:(FileSystemItem *)destination {
  
}

- (id<RACSubscribable>)copyTo:(FileSystemItem *)destination {
  
}

- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy {
  
}

- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy {
  
}

- (id<RACSubscribable>)delete {
  
}

@end

@implementation FileSystemItem (ExtendedAttributes)

- (RACPropertySyncSubject *)extendedAttributeForKey:(NSString *)key {
  ASSERT(self.extendedAttributes);
  @synchronized(self.extendedAttributes) {
    RACPropertySyncSubject *extendedAttribute = [self.extendedAttributes objectForKey:key];
    if (!extendedAttribute) {
      extendedAttribute = [RACPropertySyncSubject subject];
      [extendedAttribute sendNext:nil];
      [self.extendedAttributes setObject:extendedAttribute forKey:key];
    }
    return extendedAttribute;
  }
}

@end

@implementation FileSystemItem (Directory_Private)

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock {
  static NSArray *(^filterAndSortByAbbreviationBlock)(RACTuple *) = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    filterAndSortByAbbreviationBlock = ^NSArray *(RACTuple *tuple) {
      NSArray *content = tuple.first;
      NSString *abbreviation = tuple.second;
      
      // No abbreviation, no need to filter
      if (![abbreviation length]) {
        return [[[content rac_toSubscribable] select:^id(NSURL *url) {
          return [RACTuple tupleWithObjectsFromArray:@[url, [RACTupleNil tupleNil]]];
        }] toArray];
      }
      
      // Filter the content
      NSMutableArray *filteredContent = [[[[[content rac_toSubscribable] select:^id(NSURL *url) {
        NSIndexSet *hitMask = nil;
        float score = [[url lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
        return [RACTuple tupleWithObjectsFromArray:@[url, hitMask ? : [RACTupleNil tupleNil], @(score)]];
      }] where:^BOOL(RACTuple *item) {
        return [item.third floatValue] > 0;
      }] toArray] mutableCopy];
      
      // Sort the filtered content
      [filteredContent sortUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
        float score1 = [[tuple1 third] floatValue];
        float score2 = [[tuple2 third] floatValue];
        if (score1 < score2) {
          return NSOrderedAscending;
        } else if (score1 > score2) {
          return NSOrderedDescending;
        } else {
          return NSOrderedSame;
        }
      }];
      return filteredContent;
    };
  });
  return filterAndSortByAbbreviationBlock;
}

- (id<RACSubscribable>)internalChildren {
  return [self internalChildrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    if (!self.urlBacking || ![[self.typeBacking first] isEqualToString:NSURLFileResourceTypeDirectory]) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
    NSMutableArray *content = [NSMutableArray array];
    for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:[self.urlBacking first] includingPropertiesForKeys:nil options:options errorHandler:nil]) {
      [content addObject:childURL];
    }
    [subject sendNext:content];
    return subject;
  }];
}

@end
