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
+ (id<RACSubscribable>)itemWithURL:(NSURL *)url type:(NSString *)type;
+ (id<RACSubscribable>)internalItemWithURL:(NSURL *)url type:(NSString *)type;

@property (nonatomic, strong) RACReplaySubject *urlBacking;
@property (nonatomic, strong) RACReplaySubject *typeBacking;

@property (nonatomic, strong) NSMutableDictionary *extendedAttributes;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemFile ()

@property (nonatomic, strong) RACPropertySyncSubject *stringContentBacking;

@end

@interface FileSystemDirectory ()

@property (nonatomic, strong) RACReplaySubject *childrenBacking;

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
  return [self itemWithURL:url type:nil];
}

+ (id<RACSubscribable>)itemWithURL:(NSURL *)url type:(NSString *)type {
  return [[[self internalItemWithURL:url type:type] subscribeOn:[self fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

+ (id<RACSubscribable>)internalItemWithURL:(NSURL *)url type:(NSString *)type {
  if (!url || ![url isFileURL]) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    FileSystemItem *item = [[self itemCache] objectForKey:url];
    if (item) {
      ASSERT([item.urlBacking.first isEqual:url]);
      if (type && ![item.typeBacking.first isEqual:type]) {
        return [RACSubscribable error:[[NSError alloc] init]];
      }
      return [RACSubscribable return:item];
    }
    NSString *detectedType = nil;
    [url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL];
    if (detectedType && type && ![detectedType isEqual:type]) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    NSString *finalType = type ? : detectedType;
    Class finalClass = nil;
    if (finalType == NSURLFileResourceTypeRegular) {
      finalClass = [FileSystemFile class];
    } else if (finalType == NSURLFileResourceTypeDirectory) {
      finalClass = [FileSystemDirectory class];
    } else {
      finalClass = [FileSystemItem class];
    }
    item = [[finalClass alloc] initWithURL:url type:finalType];
    if (!item) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    [[self itemCache] setObject:item forKey:url];
    return [RACSubscribable return:item];
  }];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  ASSERT_NOT_MAIN_QUEUE();
  self = [super init];
  if (!self) {
    return nil;
  }
  self.urlBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [self.urlBacking sendNext:url];
  self.typeBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [self.typeBacking sendNext:type];
  self.extendedAttributes = [NSMutableDictionary dictionary];
  return self;
}

- (id<RACSubscribable>)url {
  return self.urlBacking;
}

- (id<RACSubscribable>)type {
  return self.typeBacking;
}

- (id<RACSubscribable>)name {
  return [[self.url select:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }] distinctUntilChanged];
}

- (id<RACSubscribable>)parent {
  return [FileSystemItem itemWithURL:[self.url.first URLByDeletingLastPathComponent] type:NSURLFileResourceTypeDirectory];
}

- (id<RACSubscribable>)create {
  
}

- (id<RACSubscribable>)save {
  
}

- (id<RACSubscribable>)duplicate {
  
}

@end

@implementation FileSystemFile

+ (id<RACSubscribable>)fileWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeRegular];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  self = [super initWithURL:url type:type];
  if (!self) {
    return nil;
  }
  self.stringContentBacking = [RACPropertySyncSubject subject];
  NSError *error;
  NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
  if (!error) {
    [self.stringContentBacking sendNext:content];
  } else {
    [self.stringContentBacking sendError:error];
  }
  return self;
}

- (RACPropertySyncSubject *)stringContent {
  return self.stringContentBacking;
}

@end

@implementation FileSystemDirectory

+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeDirectory];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  self = [super initWithURL:url type:type];
  if (!self) {
    return nil;
  }
  NSMutableArray *children = [[NSMutableArray alloc] init];
  for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:[self.urlBacking first] includingPropertiesForKeys:nil options:0 errorHandler:nil]) {
    FileSystemItem *child = [[FileSystemItem internalItemWithURL:childURL type:nil] first];
    if (child) {
      [children addObject:child];
    }
  }
  _childrenBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [_childrenBacking sendNext:children.copy];
  return self;
}

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

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock {
  static NSArray *(^filterAndSortByAbbreviationBlock)(RACTuple *) = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    filterAndSortByAbbreviationBlock = ^NSArray *(RACTuple *tuple) {
      NSArray *content = tuple.first;
      NSString *abbreviation = tuple.second;
      
      // No abbreviation, no need to filter
      if (![abbreviation length]) {
        return [[[content rac_toSubscribable] select:^id(FileSystemItem *item) {
          return [RACTuple tupleWithObjectsFromArray:@[item, [RACTupleNil tupleNil]]];
        }] toArray];
      }
      
      // Filter the content
      NSMutableArray *filteredContent = [[[[[content rac_toSubscribable] select:^id(FileSystemItem *item) {
        NSIndexSet *hitMask = nil;
        float score = [item.name.first scoreForAbbreviation:abbreviation hitMask:&hitMask];
        return [RACTuple tupleWithObjectsFromArray:@[item, hitMask ? : [RACTupleNil tupleNil], @(score)]];
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
  return self.childrenBacking;
}

@end

@implementation FileSystemItem (FileManagement)

- (id<RACSubscribable>)moveTo:(FileSystemDirectory *)destination {
  
}

- (id<RACSubscribable>)copyTo:(FileSystemDirectory *)destination {
  
}

- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy {
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    NSURL *url = self.urlBacking.first;
    NSError *error = nil;
    if (!copy) {
      [[NSFileManager defaultManager] moveItemAtURL:url toURL:[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName] error:&error];
    } else {
      [[NSFileManager defaultManager] copyItemAtURL:url toURL:[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName] error:&error];
    }
    if (error) {
      return [RACSubscribable error:error];
    }
    return [RACSubscribable return:[RACUnit defaultUnit]];
  }] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
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
