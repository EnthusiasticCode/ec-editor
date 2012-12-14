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
#define ASSERT_FS_SCHEDULER() ASSERT(RACScheduler.currentScheduler == fsScheduler_debug && fsScheduler_debug != nil)
static RACScheduler *fsScheduler_debug = nil;
#else
#define ASSERT_FS_SCHEDULER()
#endif

static RACScheduler *fsScheduler() {
  static RACScheduler *fsScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
		fsScheduler = [RACScheduler scheduler];
#if DEBUG
    fsScheduler_debug = fsScheduler;
#endif
  });
  return fsScheduler;
}

static RACScheduler *currentScheduler() {
	ASSERT(RACScheduler.currentScheduler);
  return RACScheduler.currentScheduler;
}

// Cache of existing FileSystemItems, used for uniquing
static NSMutableDictionary *fsItemCache() {
  ASSERT_FS_SCHEDULER();
  static NSMutableDictionary *itemCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    itemCache = [NSMutableDictionary dictionary];
  });
  return itemCache;
}


@interface FileSystemItem ()

+ (id<RACSignal>)itemWithURL:(NSURL *)url type:(NSString *)type;
+ (id<RACSignal>)internalItemWithURL:(NSURL *)url type:(NSString *)type;

@property (nonatomic, strong, readonly) RACReplaySubject *urlBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *typeBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *parentBacking;

@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemFile ()

@property (nonatomic, strong, readonly) RACReplaySubject *encodingBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *contentBacking;

- (id<RACSignal>)internalSave;

@end

@interface FileSystemDirectory ()

@property (nonatomic, strong, readonly) RACReplaySubject *childrenBacking;

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock;
- (id<RACSignal>)internalChildren;
- (id<RACSignal>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options;
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

+ (id<RACSignal>)itemWithURL:(NSURL *)url {
  return [self itemWithURL:url type:nil];
}

+ (id<RACSignal>)itemWithURL:(NSURL *)url type:(NSString *)type {
  return [[[self internalItemWithURL:url type:type] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

+ (id<RACSignal>)internalItemWithURL:(NSURL *)url type:(NSString *)type {
  if (!url || ![url isFileURL]) {
    return [RACSignal error:[[NSError alloc] init]];
  }
  return [RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    FileSystemItem *item = fsItemCache()[url];
    if (item) {
      ASSERT([item.urlBacking.first isEqual:url]);
      if (type && ![item.typeBacking.first isEqual:type]) {
        return [RACSignal error:[[NSError alloc] init]];
      }
      return [RACSignal return:item];
    }
    NSString *detectedType = nil;
    if (![url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL]) {
      return [RACSignal error:[[NSError alloc] init]];
    }
    if (!detectedType || (type && ![detectedType isEqual:type])) {
      return [RACSignal error:[[NSError alloc] init]];
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
      return [RACSignal error:[[NSError alloc] init]];
    }
    fsItemCache()[url] = item;
    return [RACSignal return:item];
  }];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  ASSERT_FS_SCHEDULER();
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

- (id<RACSignal>)url {
  return [self.urlBacking deliverOn:currentScheduler()];
}

- (id<RACSignal>)type {
  return [self.typeBacking deliverOn:currentScheduler()];
}

- (id<RACSignal>)name {
  return [[self.urlBacking map:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }] deliverOn:currentScheduler()];
}

- (id<RACSignal>)parent {
  return [FileSystemItem itemWithURL:[self.urlBacking.first URLByDeletingLastPathComponent] type:NSURLFileResourceTypeDirectory];
}

@end

@implementation FileSystemFile

+ (id<RACSignal>)fileWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeRegular];
}

+ (id<RACSignal>)createFileWithURL:(NSURL *)url {
  if (!url || ![url isFileURL]) {
    return [RACSignal error:[[NSError alloc] init]];
  }
  return [[[RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    NSError *error = nil;
    if (![[[NSData alloc] init] writeToURL:url options:NSDataWritingWithoutOverwriting error:&error]) {
      return [RACSignal error:error];
    }
    [self didCreate:url];
    return [self fileWithURL:url];
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSignal>)encodingSource {
  @weakify(self);
  return [[[RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSignal error:[[NSError alloc] init]];
    }
    return self.encodingBacking;
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)encodingSink {
  RACSubject *sink = [RACSubject subject];
  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
    ASSERT_FS_SCHEDULER();
    [self.encodingBacking sendNext:x];
  }];
  return self.encodingBacking;
}

- (id<RACSignal>)contentSource {
  @weakify(self);
  return [[[RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSignal error:[[NSError alloc] init]];
    }
    return self.contentBacking;
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)contentSink {
  RACSubject *sink = [RACSubject subject];
//  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
//    ASSERT_FS_SCHEDULER();
//    [self.contentBacking sendNext:x];
//  }];
  return sink;
}

- (id<RACSignal>)save {
  return [[[self internalSave] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

@synthesize encodingBacking = _encodingBacking;

- (RACReplaySubject *)encodingBacking {
  ASSERT_FS_SCHEDULER();
  if (!_encodingBacking) {
    _encodingBacking = [RACReplaySubject replaySubjectWithCapacity:1];
    
  }
  return _encodingBacking;
}

@synthesize contentBacking = _contentBacking;

- (RACReplaySubject *)contentBacking {
  ASSERT_FS_SCHEDULER();
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

- (id<RACSignal>)internalSave {
  @weakify(self);
  return [RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    @strongify(self);
    NSString *content = self.contentBacking.first;
    ASSERT(self.encodingBacking.first);
    NSStringEncoding encoding = [self.encodingBacking.first unsignedIntegerValue];
    NSURL *url = self.urlBacking.first;
    if (!url) {
      return [RACSignal error:[[NSError alloc] init]];
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
      return [RACSignal error:error];
    }
    return [RACSignal return:self];
  }];
}

@end

@implementation FileSystemDirectory

+ (id<RACSignal>)directoryWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeDirectory];
}

+ (id<RACSignal>)createDirectoryWithURL:(NSURL *)url {
  if (!url || ![url isFileURL]) {
    return [RACSignal error:[[NSError alloc] init]];
  }
  return [[[RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
      return [RACSignal error:error];
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

- (id<RACSignal>)children {
  return [[[self internalChildren] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSignal>)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
  return [[[self internalChildrenWithOptions:options] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSignal>)childrenFilteredByAbbreviation:(id<RACSignal>)abbreviationSignal {
  return [[[RACSignal combineLatest:@[[[self internalChildren] subscribeOn:fsScheduler()], [abbreviationSignal ?: [RACSignal return:nil] deliverOn:fsScheduler()]]] map:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:currentScheduler()];
}

- (id<RACSignal>)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSignal>)abbreviationSignal {
  return [[[RACSignal combineLatest:@[[[self internalChildrenWithOptions:options] subscribeOn:fsScheduler()], [abbreviationSignal ?: [RACSignal return:nil] deliverOn:fsScheduler()]]] map:[[self class] filterAndSortByAbbreviationBlock]] deliverOn:currentScheduler()];
}

+ (NSArray *(^)(RACTuple *))filterAndSortByAbbreviationBlock {
  static NSArray *(^filterAndSortByAbbreviationBlock)(RACTuple *) = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    filterAndSortByAbbreviationBlock = ^NSArray *(RACTuple *tuple) {
      ASSERT_FS_SCHEDULER();
      NSArray *content = tuple.first;
      NSString *abbreviation = tuple.second;
      
      // No abbreviation, no need to filter, sort it by lastPathComponent
      if (![abbreviation length]) {
        return [[content sortedArrayUsingComparator:^NSComparisonResult(FileSystemItem *obj1, FileSystemItem *obj2) {
          return [[obj1.urlBacking.first lastPathComponent] compare:[obj2.urlBacking.first lastPathComponent]];
        }] map:^id(FileSystemItem *item) {
          return [RACTuple tupleWithObjectsFromArray:@[item, [RACTupleNil tupleNil]]];
        }];
      }
      
      // Filter the content
      NSMutableArray *filteredContent = [[[content map:^id(FileSystemItem *item) {
        NSIndexSet *hitMask = nil;
        float score = [[item.urlBacking.first lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
        return [RACTuple tupleWithObjectsFromArray:@[item, hitMask ? : [RACTupleNil tupleNil], @(score)]];
      }] filter:^BOOL(RACTuple *item) {
        return [item.third floatValue] > 0;
      }] mutableCopy];
      
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

- (id<RACSignal>)internalChildren {
  return [self internalChildrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (id<RACSignal>)internalChildrenWithOptions:(NSDirectoryEnumerationOptions)options {
  ASSERT(!(options & NSDirectoryEnumerationSkipsPackageDescendants) && "FileSystemDirectory doesn't support NSDirectoryEnumerationSkipsPackageDescendants");
  @weakify(self);
  return [RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    @strongify(self);
    id<RACSignal>result = self.childrenBacking;
    
    // Filter out hidden files if needed
    if (options & NSDirectoryEnumerationSkipsHiddenFiles) {
      result = [[result map:^id<RACSignal>(NSArray *x) {
        if (!x.count) {
          return [RACSignal return:x];
        }
        NSMutableArray *namedItems = [[NSMutableArray alloc] init];
        for (FileSystemItem *item in x) {
          [namedItems addObject:[item.name map:^RACTuple *(NSString *x) {
            return [RACTuple tupleWithObjectsFromArray:@[item, x ? : [RACTupleNil tupleNil]]];
          }]];
        }
        return [[RACSignal combineLatest:namedItems] map:^NSArray *(RACTuple *xs) {
          NSMutableArray *nonHiddenItems = [[NSMutableArray alloc] init];
          for (RACTuple *namedItem in xs) {
            FileSystemItem *item = namedItem.first;
            NSString *name = namedItem.second;
            if (name && [name characterAtIndex:0] != L'.') {
              [nonHiddenItems addObject:item];
            }
          }
          return nonHiddenItems;
        }];
      }] switch];
    }
    
    // Merge in descendants if needed
    if (!(options & NSDirectoryEnumerationSkipsSubdirectoryDescendants)) {
      result = [[result map:^id<RACSignal>(NSArray *x) {
        if (!x.count) {
          return [RACSignal return:x];
        }
        NSMutableArray *descendantSignals = [[NSMutableArray alloc] init];
        for (FileSystemItem *item in x) {
          if (item.typeBacking.first == NSURLFileResourceTypeDirectory) {
            [descendantSignals addObject:[[((FileSystemDirectory *)item) childrenWithOptions:options] map:^NSArray *(NSArray *x) {
              return [@[item] arrayByAddingObjectsFromArray:x];
            }]];
          } else {
            [descendantSignals addObject:[RACSignal return:@[item]]];
          }
        }
        return [[RACSignal combineLatest:descendantSignals] map:^NSArray *(RACTuple *xs) {
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
  ASSERT_FS_SCHEDULER();
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

- (id<RACSignal>)moveTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *destinationURL = [destination.urlBacking.first URLByAppendingPathComponent:newName ?: url.lastPathComponent];
    NSError *error = nil;
		if (shouldReplace && [NSFileManager.defaultManager fileExistsAtPath:destinationURL.path]) {
			[NSFileManager.defaultManager removeItemAtURL:destinationURL error:&error];
		}
    if (![NSFileManager.defaultManager moveItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didMove:url to:destinationURL];
      [result sendNext:self];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:currentScheduler()];
}

- (id<RACSignal>)moveTo:(FileSystemDirectory *)destination {
  return [self moveTo:destination withName:nil replaceExisting:YES];
}

- (id<RACSignal>)copyTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSURL *destinationURL = [destination.urlBacking.first URLByAppendingPathComponent:newName ?: url.lastPathComponent];
    NSError *error = nil;
		if (shouldReplace && [NSFileManager.defaultManager fileExistsAtPath:destinationURL.path]) {
			[NSFileManager.defaultManager removeItemAtURL:destinationURL error:&error];
		}
    if (![NSFileManager.defaultManager copyItemAtURL:url toURL:destinationURL error:&error]) {
      [result sendError:error];
    } else {
      [[self class] didCopy:url to:destinationURL];
      [result sendNext:[[self class] internalItemWithURL:destinationURL type:nil]];
      [result sendCompleted];
    }
  }];
  return [result deliverOn:currentScheduler()];
}

- (id<RACSignal>)copyTo:(FileSystemDirectory *)destination {
  return [self copyTo:destination withName:nil replaceExisting:YES];
}

- (id<RACSignal>)renameTo:(NSString *)newName {
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

- (id<RACSignal>)duplicate {
  RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
  @weakify(self);
  [fsScheduler() schedule:^{
    @strongify(self);
    NSURL *url = self.urlBacking.first;
    NSUInteger duplicateCount = 1;
		NSURL *destinationURL = nil;
    for (;;) {
			destinationURL = [url.URLByDeletingLastPathComponent URLByAppendingPathComponent:(url.pathExtension.length == 0 ? [NSString stringWithFormat:@"%@ (%d)", url.lastPathComponent, duplicateCount] : [NSString stringWithFormat:@"%@ (%d).%@", url.lastPathComponent.stringByDeletingPathExtension, duplicateCount, url.pathExtension])];
      if (![[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path]) {
        break;
      }
      ++duplicateCount;
    }
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

- (id<RACSignal>)exportTo:(NSURL *)destination copy:(BOOL)copy {
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

- (id<RACSignal>)delete {
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
  ASSERT_FS_SCHEDULER();
  [[fsItemCache()[source] urlBacking] sendNext:destination];
  NSURL *sourceParent = [source URLByDeletingLastPathComponent];
  NSURL *destinationParent = [destination URLByDeletingLastPathComponent];
  if (![sourceParent isEqual:destinationParent]) {
    [fsItemCache()[sourceParent] didChangeChildren];
    [fsItemCache()[destinationParent] didChangeChildren];
  }
}

+ (void)didCopy:(NSURL *)source to:(NSURL *)destination {
  ASSERT_FS_SCHEDULER();
  [fsItemCache()[[destination URLByDeletingLastPathComponent]] didChangeChildren];
}

+ (void)didCreate:(NSURL *)target {
  ASSERT_FS_SCHEDULER();
  [fsItemCache()[[target URLByDeletingLastPathComponent]] didChangeChildren];
}

+ (void)didDelete:(NSURL *)target {
  ASSERT_FS_SCHEDULER();
  FileSystemItem *item = fsItemCache()[target];
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
  [fsItemCache()[[target URLByDeletingLastPathComponent]] didChangeChildren];
}

@end

@implementation FileSystemItem (ExtendedAttributes)

- (id<RACSignal>)extendedAttributeSourceForKey:(NSString *)key {
  @weakify(self);
  return [[[RACSignal defer:^id<RACSignal>{
    ASSERT_FS_SCHEDULER();
    @strongify(self);
    if (!self || !self.urlBacking.first) {
      return [RACSignal error:[[NSError alloc] init]];
    }
    return [self extendedAttributeBackingForKey:key];
  }] subscribeOn:fsScheduler()] deliverOn:currentScheduler()];
}

- (id<RACSubscriber>)extendedAttributeSinkForKey:(NSString *)key {
  RACSubject *sink = [RACSubject subject];
  [[sink deliverOn:fsScheduler()] subscribeNext:^(id x) {
    ASSERT_FS_SCHEDULER();
    [[self extendedAttributeBackingForKey:key] sendNext:x];
  }];
  return sink;
}

@end

@implementation FileSystemItem (ExtendedAttributes_Private)

- (RACReplaySubject *)extendedAttributeBackingForKey:(NSString *)key {
  ASSERT_FS_SCHEDULER();
  static size_t _xattrMaxSize = 4 * 1024; // 4 kB
  
  RACReplaySubject *backing = (self.extendedAttributesBacking)[key];
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
      ASSERT_FS_SCHEDULER();
      if (x) {
        NSData *xattrData = [NSKeyedArchiver archivedDataWithRootObject:x];
        setxattr(((NSURL *)self.urlBacking.first).path.fileSystemRepresentation, key.UTF8String, [xattrData bytes], [xattrData length], 0, 0);
      } else {
        removexattr(((NSURL *)self.urlBacking.first).path.fileSystemRepresentation, key.UTF8String, 0);
      }
    }];
    
    (self.extendedAttributesBacking)[key] = backing;
  }
  return backing;
  
}

@end
