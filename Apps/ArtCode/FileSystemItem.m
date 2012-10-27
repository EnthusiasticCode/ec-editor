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
@property (nonatomic, strong) RACReplaySubject *parentBacking;

@property (nonatomic, strong) NSMutableDictionary *extendedAttributes;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemDirectory ()

@property (nonatomic, strong) RACReplaySubject *childrenBacking;

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock;
- (id<RACSubscribable>)internalChildren;
- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options;
- (void)didChangeChildren;

@end

@interface FileSystemItem (FileManagement_Private)

+ (void)didMove:(NSURL *)source to:(NSURL *)destination;
+ (void)didCopy:(NSURL *)source to:(NSURL *)destination;
+ (void)didDelete:(NSURL *)target;

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
  _urlBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [_urlBacking sendNext:url];
  _typeBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [_typeBacking sendNext:type];
  _parentBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  _extendedAttributes = [NSMutableDictionary dictionary];
  return self;
}

- (id<RACSubscribable>)url {
  return [self.urlBacking deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)type {
  return [self.typeBacking deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)name {
  return [[self.urlBacking select:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)parent {
  return [FileSystemItem itemWithURL:[self.urlBacking.first URLByDeletingLastPathComponent] type:NSURLFileResourceTypeDirectory];
}

- (id<RACSubscribable>)save {
  
}

@end

@implementation FileSystemFile

+ (id<RACSubscribable>)fileWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeRegular];
}

+ (id<RACSubscribable>)createFileWithURL:(NSURL *)url {
  
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  self = [super initWithURL:url type:type];
  if (!self) {
    return nil;
  }
  _stringContent = [RACPropertySyncSubject subject];
  NSError *error;
  NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
  if (!error) {
    [_stringContent sendNext:content];
  } else {
    [_stringContent sendError:error];
  }
  return self;
}

@end

@implementation FileSystemDirectory

+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeDirectory];
}

+ (id<RACSubscribable>)createDirectoryWithURL:(NSURL *)url {
  
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  self = [super initWithURL:url type:type];
  if (!self) {
    return nil;
  }
  _childrenBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [self didChangeChildren];
  return self;
}

- (id<RACSubscribable>)children {
  return [[[self internalChildren] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [[[self internalChildrenWithOptions:options] subscribeOn:[[self class] fileSystemScheduler]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[[RACSubscribable combineLatest:@[[[self internalChildren] subscribeOn:[[self class] fileSystemScheduler]], abbreviationSubscribable]] deliverOn:[[self class] fileSystemScheduler]] select:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[[RACSubscribable combineLatest:@[[[self internalChildrenWithOptions:options] subscribeOn:[[self class] fileSystemScheduler]], abbreviationSubscribable]] deliverOn:[[self class] fileSystemScheduler]] select:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock {
  static NSArray *(^filterAndSortByAbbreviationBlock)(RACTuple *) = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    filterAndSortByAbbreviationBlock = ^NSArray *(RACTuple *tuple) {
      ASSERT_NOT_MAIN_QUEUE();
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
        float score = [[item.urlBacking.first lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
        return [RACTuple tupleWithObjectsFromArray:@[item, hitMask ? : [RACTupleNil tupleNil], @(score)]];
      }] where:^BOOL(RACTuple *item) {
        return [item.third floatValue] > 0;
      }] toArray] mutableCopy];
      
      // Sort the filtered content
      [filteredContent sortUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
        float score1 = [[tuple1 third] floatValue];
        float score2 = [[tuple2 third] floatValue];
        if (score1 > score2) {
          return NSOrderedAscending;
        } else if (score1 < score2) {
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

- (void)didChangeChildren {
  NSMutableArray *children = [[NSMutableArray alloc] init];
  for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:[self.urlBacking first] includingPropertiesForKeys:nil options:0 errorHandler:nil]) {
    FileSystemItem *child = [[FileSystemItem internalItemWithURL:childURL type:nil] first];
    if (child) {
      [children addObject:child];
    }
  }
  [self.childrenBacking sendNext:children.copy];
}

@end

@implementation FileSystemItem (FileManagement)

- (id<RACSubscribable>)moveTo:(FileSystemDirectory *)destination {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *destinationURL = [destination.urlBacking.first URLByAppendingPathComponent:[url lastPathComponent]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didMove:url to:destinationURL];
      [result sendNext:self];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)copyTo:(FileSystemDirectory *)destination {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *destinationURL = [destination.urlBacking.first URLByAppendingPathComponent:[url lastPathComponent]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] copyItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didCopy:url to:destinationURL];
      [result sendNext:[[self class] internalItemWithURL:destinationURL type:nil]];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)renameTo:(NSString *)newName copy:(BOOL)copy {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *newURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName];
    NSError *error = nil;
    if (!copy) {
      if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:newURL error:&error]) {
        [result sendError:error];
      } else {
        [[self class] didMove:url to:newURL];
        [result sendNext:self];
        [result sendCompleted];
      }
    } else {
      if (![[NSFileManager defaultManager] copyItemAtURL:url toURL:newURL error:&error]) {
        [result sendError:error];
      } else {
        [[self class] didCopy:url to:newURL];
        [result sendNext:[[self class] internalItemWithURL:newURL type:nil]];
        [result sendCompleted];
      }
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)duplicate {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSString *name = [[url lastPathComponent] stringByDeletingPathExtension];
    NSUInteger duplicateCount = 1;
    NSString *extension = [url pathExtension];
    for (;;) {
      if (![[NSFileManager defaultManager] fileExistsAtPath:[[[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", name, duplicateCount, extension]] path]]) {
        break;
      }
      ++duplicateCount;
    }
    NSURL *destinationURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).%@", name, duplicateCount, extension]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] copyItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didCopy:url to:destinationURL];
      [result sendNext:[[self class] internalItemWithURL:destinationURL type:nil]];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSError *error = nil;
    if (!copy) {
      if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:destination error:&error]) {
        [result sendError:error];
      } else {
        [[self class] didDelete:url];
        [result sendNext:destination];
        [result sendCompleted];
      }
    } else {
      if (![[NSFileManager defaultManager] copyItemAtURL:url toURL:destination error:&error]) {
        [result sendError:error];
      } else {
        [result sendNext:destination];
        [result sendCompleted];
      }
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

- (id<RACSubscribable>)delete {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [[[self class] fileSystemScheduler] schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:url error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didDelete:url];
      [result sendNext:self];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:[RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]]];
}

@end

@implementation FileSystemItem (FileManagement_Private)

+ (void)didMove:(NSURL *)source to:(NSURL *)destination {
  [[[[self itemCache] objectForKey:source] urlBacking] sendNext:destination];
  NSURL *sourceParent = [source URLByDeletingLastPathComponent];
  NSURL *destinationParent = [destination URLByDeletingLastPathComponent];
  if (![sourceParent isEqual:destinationParent]) {
    [[[self itemCache] objectForKey:sourceParent] didChangeChildren];
    [[[self itemCache] objectForKey:destinationParent] didChangeChildren];
  }
}

+ (void)didCopy:(NSURL *)source to:(NSURL *)destination {
  [[[self itemCache] objectForKey:[destination URLByDeletingLastPathComponent]] didChangeChildren];
}

+ (void)didDelete:(NSURL *)target {
  [[[[self itemCache] objectForKey:target] urlBacking] sendNext:nil];
  [[[self itemCache] objectForKey:[target URLByDeletingLastPathComponent]] didChangeChildren];
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
