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
#import <libkern/OSAtomic.h>

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

static RACSignal *(^filterAndSortByAbbreviationBlock)(RACTuple *tuple) = ^(RACTuple *tuple) {
	NSArray *content = tuple.first;
	NSString *abbreviation = tuple.second;
	
	// No abbreviation, no need to filter
	if (![abbreviation length]) {
		return [RACSignal return:[content.rac_sequence.eagerSequence map:^id(id value) {
			return [RACTuple tupleWithObjects:value, nil];
		}].array];
	}
	
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[RACScheduler.scheduler schedule:^{
			ASSERT_NOT_MAIN_QUEUE();
			// Filter the content
			[[[RACSignal zip:[content.rac_sequence.eagerSequence map:^(FileSystemItem *item) {
				return item.url;
			}]] take:1] subscribeNext:^(RACTuple *urls) {
				NSArray *filteredContent = [[[RACSequence zip:@[ content.rac_sequence, urls.allObjects.rac_sequence ]] map:^id(RACTuple *value) {
					RACTupleUnpack(FileSystemItem *item, NSURL *url) = value;
					NSIndexSet *hitMask = nil;
					float score = [[url lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
					return [RACTuple tupleWithObjects:item, hitMask ? : [RACTupleNil tupleNil], @(score), nil];
				}] filter:^BOOL(RACTuple *item) {
					return [item.third floatValue] > 0;
				}].array;
				NSArray *sortedContent = [filteredContent sortedArrayUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
					NSNumber *score1 = tuple1.third;
					NSNumber *score2 = tuple2.third;
					if (score1.floatValue > score2.floatValue) {
						return NSOrderedAscending;
					} else if (score1.floatValue < score2.floatValue) {
						return NSOrderedDescending;
					} else {
						return NSOrderedSame;
					}
				}];
				[subscriber sendNext:sortedContent];
				[subscriber sendCompleted];
			} error:^(NSError *error) {
				[subscriber sendError:error];
			} completed:^{
				[subscriber sendCompleted];
			}];
		}];
		
		return disposable;
	}];
};

@interface FileSystemItem ()

+ (RACSignal *)itemWithURL:(NSURL *)url type:(NSString *)type;

@property (nonatomic, strong, readonly) RACReplaySubject *urlBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *typeBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *parentBacking;

@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemFile ()

@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, strong) NSString *content;

- (void)internalLoadFileIfNeeded;

@end

@interface FileSystemDirectory ()

@property (nonatomic, strong, readonly) RACReplaySubject *childrenBacking;

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

+ (RACSignal *)itemWithURL:(NSURL *)url {
  return [self itemWithURL:url type:nil];
}

+ (RACSignal *)itemWithURL:(NSURL *)url type:(NSString *)type {
	if (![url isFileURL]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[fsScheduler() schedule:^{
			ASSERT_FS_SCHEDULER();
			if (wasDisposed) return;
			FileSystemItem *item = fsItemCache()[url];
			if (item) {
				ASSERT([item.urlBacking.first isEqual:url]);
				if (type && ![item.typeBacking.first isEqual:type]) {
					[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
					return;
				}
				[subscriber sendNext:item];
				[subscriber sendCompleted];
				return;
			}
			if (wasDisposed) return;
			NSString *detectedType = nil;
			if (![url getResourceValue:&detectedType forKey:NSURLFileResourceTypeKey error:NULL] || !detectedType || (type && ![detectedType isEqual:type])) {
				[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			if (wasDisposed) return;
			Class finalClass = nil;
			if (detectedType == NSURLFileResourceTypeRegular) {
				finalClass = [FileSystemFile class];
			} else if (detectedType == NSURLFileResourceTypeDirectory) {
				finalClass = [FileSystemDirectory class];
			} else {
				finalClass = [FileSystemItem class];
			}
			if (wasDisposed) return;
			item = [[finalClass alloc] initWithURL:url type:detectedType];
			if (!item) {
				[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			if (wasDisposed) return;
			fsItemCache()[url] = item;
			[subscriber sendNext:item];
			[subscriber sendCompleted];
		}];
		
		return disposable;
	}] deliverOn:currentScheduler()];
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

- (RACSignal *)url {
  return self.urlBacking;
}

- (RACSignal *)type {
  return self.typeBacking;
}

- (RACSignal *)name {
  return [self.urlBacking map:^NSString *(NSURL *url) {
    return url.lastPathComponent;
  }];
}

- (RACSignal *)parent {
	return [[self.url map:^(NSURL *value) {
		return [FileSystemItem itemWithURL:value.URLByDeletingLastPathComponent type:NSURLFileResourceTypeDirectory];
	}] switch];
}

@end

@implementation FileSystemFile

+ (RACSignal *)fileWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeRegular];
}

+ (RACSignal *)createFileWithURL:(NSURL *)url {
  if (![url isFileURL]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[fsScheduler() schedule:^{
			ASSERT_FS_SCHEDULER();
			if (wasDisposed) return;
			NSError *error = nil;
			if (![[[NSData alloc] init] writeToURL:url options:NSDataWritingWithoutOverwriting error:&error]) {
				[subscriber sendError:error];
				return;
			}
			[self didCreate:url];
			if (wasDisposed) return;
			[[self fileWithURL:url] subscribe:subscriber];
		}];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

- (RACSignal *)encodingSignal {
	return [[[RACSignal defer:^RACSignal *{
		[self internalLoadFileIfNeeded];
		return RACAbleWithStart(self.encoding);
	}] subscribeOn:fsScheduler()] deliverOn:[RACScheduler currentScheduler]];
}

- (RACDisposable *)bindEncodingToObject:(id)target withKeyPath:(NSString *)keyPath {
	[fsScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	return [target rac_bind:keyPath transformer:^(id value) {
		if (!value || ![value unsignedIntegerValue] || value == [NSNull null]) value = @(NSUTF8StringEncoding);
		return value;
	} onScheduler:[RACScheduler currentScheduler] toObject:self withKeyPath:@keypath(self.encoding) transformer:nil onScheduler:fsScheduler()];
}

- (RACSignal *)contentSignal {
	return [[[RACSignal defer:^RACSignal *{
		[self internalLoadFileIfNeeded];
		return RACAbleWithStart(self.content);
	}] subscribeOn:fsScheduler()] deliverOn:[RACScheduler currentScheduler]];
}

- (RACDisposable *)bindContentToObject:(id)target withKeyPath:(NSString *)keyPath {
	[fsScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	return [target rac_bind:keyPath transformer:^(id value) {
		if (!value || value == [NSNull null]) value = @"";
		return value;
	} onScheduler:[RACScheduler currentScheduler] toObject:self withKeyPath:@keypath(self.content) transformer:nil onScheduler:fsScheduler()];
}

- (RACSignal *)save {
	@weakify(self);
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[fsScheduler() schedule:^{
			ASSERT_FS_SCHEDULER();
			@strongify(self);
			if (wasDisposed) return;
			NSURL *url = self.urlBacking.first;
			if (!url) {
				[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				return;
			}
			if (!self.encoding) {
				self.encoding = NSUTF8StringEncoding;
			}
			if (!self.content) {
				self.content = @"";
			}
			if (wasDisposed) return;
			NSError *error = nil;
			// Don't save atomically so we don't lose extended attributes
			if (![self.content writeToURL:url atomically:NO encoding:self.encoding error:&error]) {
				[subscriber sendError:error];
			} else {
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

- (void)internalLoadFileIfNeeded {
	ASSERT_FS_SCHEDULER();
	if (self.content) return;
	NSStringEncoding encoding;
	self.content = [NSString stringWithContentsOfURL:self.urlBacking.first usedEncoding:&encoding error:NULL];
	self.encoding = encoding;
}

@end

@implementation FileSystemDirectory

+ (RACSignal *)directoryWithURL:(NSURL *)url {
  return [self itemWithURL:url type:NSURLFileResourceTypeDirectory];
}

+ (RACSignal *)createDirectoryWithURL:(NSURL *)url {
  if (![url isFileURL]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[fsScheduler() schedule:^{
			ASSERT_FS_SCHEDULER();
			if (wasDisposed) return;
			NSError *error = nil;
			if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
				[subscriber sendError:error];
				return;
			}
			[self didCreate:url];
			[[self directoryWithURL:url] subscribe:subscriber];
		}];
		
		return disposable;
	}] deliverOn:currentScheduler()];
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

- (RACSignal *)children {
	return [self childrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
	ASSERT(!(options & NSDirectoryEnumerationSkipsPackageDescendants) && "FileSystemDirectory doesn't support NSDirectoryEnumerationSkipsPackageDescendants");
	@weakify(self);
	return [[[RACSignal defer:^RACSignal *{
		ASSERT_NOT_MAIN_QUEUE();
		@strongify(self);
		RACSignal *result = self.childrenBacking;
		
		// Filter out hidden files if needed
		if (options & NSDirectoryEnumerationSkipsHiddenFiles) {
			result = [[result map:^RACSignal *(NSArray *x) {
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
			result = [[result map:^RACSignal *(NSArray *x) {
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
	}] subscribeOn:RACScheduler.scheduler] deliverOn:currentScheduler()];
}

- (RACSignal *)childrenFilteredByAbbreviation:(RACSignal *)abbreviationSignal {
	return [[[[RACSignal combineLatest:@[[self children], abbreviationSignal ?: [RACSignal return:nil]]] map:filterAndSortByAbbreviationBlock] switch] deliverOn:currentScheduler()];
}

- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(RACSignal *)abbreviationSignal {
	return [[[[RACSignal combineLatest:@[[self childrenWithOptions:options], abbreviationSignal ?: [RACSignal return:nil]]] map:filterAndSortByAbbreviationBlock] switch] deliverOn:currentScheduler()];
}

- (void)didChangeChildren {
	ASSERT_FS_SCHEDULER();
	NSMutableArray *children = [[NSMutableArray alloc] init];
	NSURL *url = self.urlBacking.first;
	if (!url) {
		[self.childrenBacking sendNext:nil];
	}
	for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:@[NSURLFileResourceTypeKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
		FileSystemItem *child = [[FileSystemItem itemWithURL:childURL type:nil] first];
		if (child) {
			[children addObject:child];
		}
	}
	[self.childrenBacking sendNext:children.copy];
}

@end

@implementation FileSystemItem (FileManagement)

- (RACSignal *)moveTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
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

- (RACSignal *)moveTo:(FileSystemDirectory *)destination {
	return [self moveTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)copyTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
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
			[result sendNext:[[self class] itemWithURL:destinationURL type:nil]];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
}

- (RACSignal *)copyTo:(FileSystemDirectory *)destination {
	return [self copyTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)renameTo:(NSString *)newName {
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

- (RACSignal *)duplicate {
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
			[result sendNext:[[self class] itemWithURL:destinationURL type:nil]];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
}

- (RACSignal *)exportTo:(NSURL *)destination copy:(BOOL)copy {
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

- (RACSignal *)delete {
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
			((FileSystemFile *)item).content = nil;
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

- (RACSignal *)extendedAttributeSourceForKey:(NSString *)key {
	@weakify(self);
	return [[[RACSignal defer:^RACSignal *{
		ASSERT_FS_SCHEDULER();
		@strongify(self);
		if (!self || !self.urlBacking.first) {
			return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
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
