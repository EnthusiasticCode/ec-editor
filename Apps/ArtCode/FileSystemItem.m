//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
#import "NSString+ScoreForAbbreviation.h"
#import <sys/xattr.h>


// All filesystem operations must be done on this scheduler
#if DEBUG
#define ASSERT_FS_QUEUE() ASSERT([NSOperationQueue currentQueue] == fsQueue && fsQueue != nil)
static NSOperationQueue *fsQueue = nil;
#else
#define ASSERT_FS_QUEUE()
#endif

static RACScheduler *fsScheduler() {
  static RACScheduler *fileSystemScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.name = @"FileSystemItem file system queue";
    operationQueue.maxConcurrentOperationCount = 1;
#if DEBUG
    fsQueue = operationQueue;
#endif
    fileSystemScheduler = [RACScheduler schedulerWithOperationQueue:operationQueue];
  });
  return fileSystemScheduler;
}

static RACScheduler *currentScheduler() {
  return [RACScheduler schedulerWithOperationQueue:[NSOperationQueue currentQueue]];
}

// Cache of existing FileSystemItems, used for uniquing
static NSMutableDictionary *fsItemCache() {
  ASSERT_FS_QUEUE();
  static NSMutableDictionary *itemCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    itemCache = [NSMutableDictionary dictionary];
  });
  return itemCache;
}


@interface FileSystemItem ()

+ (id<RACSubscribable>)itemWithURL:(NSURL *)url type:(NSString *)type;
+ (id<RACSubscribable>)internalItemWithURL:(NSURL *)url type:(NSString *)type;

@property (nonatomic, strong, readonly) RACReplaySubject *urlBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *typeBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *parentBacking;

@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemFile ()

@property (nonatomic, strong, readonly) RACReplaySubject *encodingBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *contentBacking;

- (id<RACSubscribable>)internalSave;

@end

@interface FileSystemDirectory ()

@property (nonatomic, strong, readonly) RACReplaySubject *childrenBacking;

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock;
- (id<RACSubscribable>)internalChildren;
- (id<RACSubscribable>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options;
- (void)didChangeChildren;

@end

@interface FileSystemItem (FileManagement_Private)

+ (void)didMove:(NSURL *)source to:(NSURL *)destination;
+ (void)didCopy:(NSURL *)source to:(NSURL *)destination;
+ (void)didCreate:(NSURL *)target;
+ (void)didDelete:(NSURL *)target;

@end

@interface FileSystemItem (ExtendedAttributes_Private)

- (RACReplaySubject *)extendedAttributeBackingForKey:(NSString *)key;

@end

@implementation FileSystemItem

+ (id<RACSubscribable>)itemWithURL:(NSURL *)url {
  return [self itemWithURL:url type:nil];
}

+ (id<RACSubscribable>)itemWithURL:(NSURL *)url type:(NSString *)type {
  return [[[self internalItemWithURL:url type:type] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

+ (id<RACSubscribable>)internalItemWithURL:(NSURL *)url type:(NSString *)type {
  if (!url || ![url isFileURL]) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    FileSystemItem *item = [fsItemCache() objectForKey:url];
    if (item) {
      ASSERT([item.urlBacking.first isEqual:url]);
      if (type && ![item.typeBacking.first isEqual:type]) {
        return [RACSubscribable error:[[NSError alloc] init]];
      }
      return [RACSubscribable return:item];
    }
    NSString *detectedType = nil;
    if (![url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL]) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    if (!detectedType || (type && ![detectedType isEqual:type])) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    Class finalClass = nil;
    if (detectedType == NSURLFileResourceTypeRegular) {
      finalClass = [FileSystemFile class];
    } else if (detectedType == NSURLFileResourceTypeDirectory) {
      finalClass = [FileSystemDirectory class];
    } else {
      finalClass = [FileSystemItem class];
    }
    item = [[finalClass alloc] initWithURL:url type:detectedType];
    if (!item) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    [fsItemCache() setObject:item forKey:url];
    return [RACSubscribable return:item];
  }];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  ASSERT_FS_QUEUE();
  self = [super init];
  if (!self) {
    return nil;
  }
  _urlBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [_urlBacking sendNext:url];
  _typeBacking = [RACReplaySubject replaySubjectWithCapacity:1];
  [_typeBacking sendNext:type];
  _extendedAttributesBacking = [[NSMutableDictionary alloc] init];
  return self;
}

- (id<RACSubscribable>)url {
  return [self.urlBacking deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)type {
  return [self.typeBacking deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)name {
  return [[self.urlBacking select:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }] deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)parent {
  return [FileSystemItem itemWithURL:[self.urlBacking.first URLByDeletingLastPathComponent] type:NSURLFileResourceTypeDirectory];
}

@end

@implementation FileSystemFile

+ (id<RACSubscribable>)fileWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeRegular];
}

+ (id<RACSubscribable>)createFileWithURL:(NSURL *)url {
  if (!url || ![url isFileURL]) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    NSError *error = nil;
    if (![[[NSData alloc] init] writeToURL:url options:NSDataWritingWithoutOverwriting error:&error]) {
      return [RACSubscribable error:error];
    }
    [self didCreate:url];
    return [self fileWithURL:url];
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)encodingSource {
  @weakify(self);
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    return self.encodingBacking;
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)encodingSink {
  RACSubject *sink = [RACSubject subject];
  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
    ASSERT_FS_QUEUE();
    [self.encodingBacking sendNext:x];
  }];
  return self.encodingBacking;
}

- (id<RACSubscribable>)contentSource {
  @weakify(self);
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    return self.contentBacking;
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)contentSink {
  RACSubject *sink = [RACSubject subject];
  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
    ASSERT_FS_QUEUE();
    [self.contentBacking sendNext:x];
  }];
  return sink;
}

- (id<RACSubscribable>)save {
  return [[[self internalSave] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

@synthesize encodingBacking = _encodingBacking;

- (RACReplaySubject *)encodingBacking {
  ASSERT_FS_QUEUE();
  if (!_encodingBacking) {
    _encodingBacking = [RACReplaySubject replaySubjectWithCapacity:1];
    
  }
  return _encodingBacking;
}

@synthesize contentBacking = _contentBacking;

- (RACReplaySubject *)contentBacking {
  ASSERT_FS_QUEUE();
  if (!_contentBacking) {
    _contentBacking = [RACReplaySubject replaySubjectWithCapacity:1];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:self.urlBacking.first encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
      [_contentBacking sendNext:content];
    } else {
      [_contentBacking sendError:error];
    }
  }
  return _contentBacking;
}

- (id<RACSubscribable>)internalSave {
  @weakify(self);
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    @strongify(self);
    NSString *content = self.contentBacking.first;
    ASSERT(self.encodingBacking.first);
    NSStringEncoding encoding = [self.encodingBacking.first unsignedIntegerValue];
    NSURL *url = self.urlBacking.first;
    if (!url) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    if (!encoding) {
      encoding = NSUTF8StringEncoding;
    }
    if (!content) {
      content = @"";
    }
    NSError *error = nil;
    // Don't save atomically so we don't lose extended attributes
    if (![content writeToURL:url atomically:NO encoding:encoding error:&error]) {
      return [RACSubscribable error:error];
    }
    return [RACSubscribable return:self];
  }];
}

@end

@implementation FileSystemDirectory

+ (id<RACSubscribable>)directoryWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeDirectory];
}

+ (id<RACSubscribable>)createDirectoryWithURL:(NSURL *)url {
  if (!url || ![url isFileURL]) {
    return [RACSubscribable error:[[NSError alloc] init]];
  }
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
      return [RACSubscribable error:error];
    }
    [self didCreate:url];
    return [self directoryWithURL:url];
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
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
  return [[[self internalChildren] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [[[self internalChildrenWithOptions:options] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)childrenFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[RACSubscribable combineLatest:@[[[self internalChildren] subscribeOn:fsScheduler()], [abbreviationSubscribable ?: [RACSubscribable return:nil] deliverOn:fsScheduler()]]] select:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable {
  return [[[RACSubscribable combineLatest:@[[[self internalChildrenWithOptions:options] subscribeOn:fsScheduler()], [abbreviationSubscribable ?: [RACSubscribable return:nil] deliverOn:fsScheduler()]]] select:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:currentScheduler()];
}

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock {
  static NSArray *(^filterAndSortByAbbreviationBlock)(RACTuple *) = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    filterAndSortByAbbreviationBlock = ^NSArray *(RACTuple *tuple) {
      ASSERT_FS_QUEUE();
      NSArray *content = tuple.first;
      NSString *abbreviation = tuple.second;
      
      // No abbreviation, no need to filter, sort it by lastPathComponent
      if (![abbreviation length]) {
        return [[[[content sortedArrayUsingComparator:^NSComparisonResult(FileSystemItem *obj1, FileSystemItem *obj2) {
          return [[obj1.urlBacking.first lastPathComponent] compare:[obj2.urlBacking.first lastPathComponent]];
        }] rac_toSubscribable] select:^id(FileSystemItem *item) {
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
  ASSERT(!(options & NSDirectoryEnumerationSkipsPackageDescendants) && "FileSystemDirectory doesn't support NSDirectoryEnumerationSkipsPackageDescendants");
  RACReplaySubject *backing = self.childrenBacking;
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    id<RACSubscribable>result = backing;
    
    // Filter out hidden files if needed
    if (options & NSDirectoryEnumerationSkipsHiddenFiles) {
      result = [[result select:^id<RACSubscribable>(NSArray *x) {
        NSMutableArray *namedItems = [[NSMutableArray alloc] init];
        for (FileSystemItem *item in x) {
          [namedItems addObject:[item.name select:^RACTuple *(NSString *x) {
            return [RACTuple tupleWithObjectsFromArray:@[item, x]];
          }]];
        }
        return [[RACSubscribable combineLatest:namedItems] select:^NSArray *(RACTuple *xs) {
          NSMutableArray *nonHiddenItems = [[NSMutableArray alloc] init];
          for (RACTuple *namedItem in xs) {
            FileSystemItem *item = namedItem.first;
            NSString *name = namedItem.second;
            if ([name characterAtIndex:0] != L'.') {
              [nonHiddenItems addObject:item];
            }
          }
          return nonHiddenItems;
        }];
      }] switch];
    }
    
    // Merge in descendants if needed
    if (!(options & NSDirectoryEnumerationSkipsSubdirectoryDescendants)) {
      result = [[result select:^id<RACSubscribable>(NSArray *x) {
        NSMutableArray *descendantSubscribables = [[NSMutableArray alloc] init];
        for (FileSystemItem *item in x) {
          if (item.typeBacking.first == NSURLFileResourceTypeDirectory) {
            [descendantSubscribables addObject:[[((FileSystemDirectory *)item) childrenWithOptions:options] select:^NSArray *(NSArray *x) {
              return [@[item] arrayByAddingObjectsFromArray:x];
            }]];
          } else {
            [descendantSubscribables addObject:[RACSubscribable return:@[item]]];
          }
        }
        return [[RACSubscribable combineLatest:descendantSubscribables] select:^NSArray *(RACTuple *xs) {
          NSMutableArray *mergedDescendants = [[NSMutableArray alloc] init];
          for (NSArray *children in xs) {
            [mergedDescendants addObjectsFromArray:children];
          }
          return mergedDescendants;
        }];
      }] switch];
    }
    
    return result;
  }];
}

- (void)didChangeChildren {
  ASSERT_FS_QUEUE();
  NSMutableArray *children = [[NSMutableArray alloc] init];
  NSURL *url = self.urlBacking.first;
  if (!url) {
    [self.childrenBacking sendNext:nil];
  }
  for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:@[NSURLFileResourceTypeKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
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
  return [self moveTo:destination renameTo:nil];
}

- (id<RACSubscribable>)moveTo:(FileSystemDirectory *)destination renameTo:(NSString *)newName {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *destinationURL = [destination.urlBacking.first URLByAppendingPathComponent:newName ?: [url lastPathComponent]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didMove:url to:destinationURL];
      [result sendNext:self];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)copyTo:(FileSystemDirectory *)destination {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
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
  return [result deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)renameTo:(NSString *)newName {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *newURL = [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:newName];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] moveItemAtURL:url toURL:newURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didMove:url to:newURL];
      [result sendNext:self];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)duplicate {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
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
  return [result deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)exportTo:(NSURL *)destination copy:(BOOL)copy {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
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
  return [result deliverOn:currentScheduler()];
}

- (id<RACSubscribable>)delete {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
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
  return [result deliverOn:currentScheduler()];
}

@end

@implementation FileSystemItem (FileManagement_Private)

+ (void)didMove:(NSURL *)source to:(NSURL *)destination {
  ASSERT_FS_QUEUE();
  [[[fsItemCache() objectForKey:source] urlBacking] sendNext:destination];
  NSURL *sourceParent = [source URLByDeletingLastPathComponent];
  NSURL *destinationParent = [destination URLByDeletingLastPathComponent];
  if (![sourceParent isEqual:destinationParent]) {
    [[fsItemCache() objectForKey:sourceParent] didChangeChildren];
    [[fsItemCache() objectForKey:destinationParent] didChangeChildren];
  }
}

+ (void)didCopy:(NSURL *)source to:(NSURL *)destination {
  ASSERT_FS_QUEUE();
  [[fsItemCache() objectForKey:[destination URLByDeletingLastPathComponent]] didChangeChildren];
}

+ (void)didCreate:(NSURL *)target {
  ASSERT_FS_QUEUE();
  [[fsItemCache() objectForKey:[target URLByDeletingLastPathComponent]] didChangeChildren];
}

+ (void)didDelete:(NSURL *)target {
  ASSERT_FS_QUEUE();
  FileSystemItem *item = [fsItemCache() objectForKey:target];
  if (item) {
    [fsItemCache() removeObjectForKey:target];
    NSString *itemType = item.typeBacking.first;
    [item.urlBacking sendNext:nil];
    [item.typeBacking sendNext:nil];
    [item.parentBacking sendNext:nil];
    if (itemType == NSURLFileResourceTypeRegular) {
      [((FileSystemFile *)item).contentBacking sendNext:nil];
    } else if (itemType == NSURLFileResourceTypeDirectory) {
      [((FileSystemDirectory *)item).childrenBacking sendNext:nil];
      NSString *targetString = target.standardizedURL.absoluteString;
      NSArray *keys = fsItemCache().allKeys.copy;
      for (NSURL *key in keys) {
        if ([key.standardizedURL.absoluteString hasPrefix:targetString]) {
          [self didDelete:key];
        }
      }
    }
  }
  [[fsItemCache() objectForKey:[target URLByDeletingLastPathComponent]] didChangeChildren];
}

@end

@implementation FileSystemItem (ExtendedAttributes)

- (id<RACSubscribable>)extendedAttributeSourceForKey:(NSString *)key {
  @weakify(self);
  return [[[RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_FS_QUEUE();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSubscribable error:[[NSError alloc] init]];
    }
    return [self extendedAttributeBackingForKey:key];
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)extendedAttributeSinkForKey:(NSString *)key {
  RACSubject *sink = [RACSubject subject];
  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
    ASSERT_FS_QUEUE();
    [[self extendedAttributeBackingForKey:key] sendNext:x];
  }];
  return sink;
}

@end

@implementation FileSystemItem (ExtendedAttributes_Private)

- (RACReplaySubject *)extendedAttributeBackingForKey:(NSString *)key {
  ASSERT_FS_QUEUE();
  static size_t _xattrMaxSize = 4 * 1024; // 4 kB
  
  RACReplaySubject *backing = [self.extendedAttributesBacking objectForKey:key];
  if (!backing) {
    backing = [RACReplaySubject replaySubjectWithCapacity:1];
    
    // Load the initial value from the filesystem
    void *xattrBytes = malloc(_xattrMaxSize);
    ssize_t xattrBytesCount = getxattr(((NSURL *)self.urlBacking.first).path.fileSystemRepresentation, key.UTF8String, xattrBytes, _xattrMaxSize, 0, 0);
    if (xattrBytesCount != -1) {
      NSData *xattrData = [NSData dataWithBytes:xattrBytes length:xattrBytesCount];
      id xattrValue = [NSKeyedUnarchiver unarchiveObjectWithData:xattrData];
      [backing sendNext:xattrValue];
    } else {
      [backing sendNext:nil];
    }
    free(xattrBytes);
    
    // Save the value to disk every time it changes
    [[backing deliverOn:fsScheduler()] subscribeNext:^(id x) {
      ASSERT_FS_QUEUE();
      if (x) {
        NSData *xattrData = [NSKeyedArchiver archivedDataWithRootObject:x];
        setxattr(((NSURL *)self.urlBacking.first).path.fileSystemRepresentation, key.UTF8String, [xattrData bytes], [xattrData length], 0, 0);
      } else {
        removexattr(((NSURL *)self.urlBacking.first).path.fileSystemRepresentation, key.UTF8String, 0);
      }
    }];

    [self.extendedAttributesBacking setObject:backing forKey:key];
  }
  return backing;

}

@end
