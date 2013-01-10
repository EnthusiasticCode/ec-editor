//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
#import "NSString+ScoreForAbbreviation.h"
#import "NSObject+RACBindings.h"
#import <sys/xattr.h>
#import <libkern/OSAtomic.h>

// All filesystem operations must be done on this scheduler
#if DEBUG
#define ASSERT_FILE_SYSTEM_SCHEDULER() ASSERT(currentScheduler() == fileSystemScheduler())
#else
#define ASSERT_FILE_SYSTEM_SCHEDULER()
#endif

static RACScheduler *fileSystemScheduler() {
  static RACScheduler *fileSystemScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
		fileSystemScheduler = [RACScheduler scheduler];
  });
  return fileSystemScheduler;
}

static RACScheduler *currentScheduler() {
	ASSERT(RACScheduler.currentScheduler);
  return RACScheduler.currentScheduler;
}

// Cache of existing FileSystemItems, used for uniquing
static NSMutableDictionary *fsItemCache() {
  ASSERT_FILE_SYSTEM_SCHEDULER();
  static NSMutableDictionary *itemCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    itemCache = [NSMutableDictionary dictionary];
  });
  return itemCache;
}

@interface FileSystemItem ()

+ (RACSignal *)itemWithURL:(NSURL *)url type:(NSString *)type;

@property (nonatomic, strong, readonly) RACReplaySubject *urlBacking;
@property (nonatomic, strong, readonly) RACReplaySubject *typeBacking;

@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type;

@end

@interface FileSystemFile ()

@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, strong) NSString *content;

- (void)internalLoadFileIfNeeded;

@end

@interface FileSystemDirectory ()

@property (nonatomic, weak) RACReplaySubject *childrenBacking;

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

@interface RACSignal (FileSystemItem)

- (RACSignal *)deliverOnCurrentSchedulerIfNotFileSystemScheduler;

@end

@implementation FileSystemItem

+ (RACSignal *)itemWithURL:(NSURL *)url {
  return [self itemWithURL:url type:nil];
}

+ (RACSignal *)itemWithURL:(NSURL *)url type:(NSString *)type {
	if (![url isFileURL]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		[disposable addDisposable:[RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}]];
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			if (wasDisposed) return;
			FileSystemItem *item = fsItemCache()[url];
			if (item) {
				RACDisposable *itemDisposable = [[[item.type take:1] flattenMap:^(NSString *value) {
					if (type && ![value isEqual:type]) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
					return [RACSignal return:item];
				}] subscribe:subscriber];
				[disposable addDisposable:itemDisposable];
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
	}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (instancetype)initWithURL:(NSURL *)url type:(NSString *)type {
  ASSERT_FILE_SYSTEM_SCHEDULER();
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
  return [self.urlBacking deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)type {
  return [self.typeBacking deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)name {
  return [self.url map:^NSString *(NSURL *url) {
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
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		[disposable addDisposable:[RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}]];
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			if (wasDisposed) return;
			NSError *error = nil;
			if (![[[NSData alloc] init] writeToURL:url options:NSDataWritingWithoutOverwriting error:&error]) {
				[subscriber sendError:error];
				return;
			}
			[self didCreate:url];
			if (wasDisposed) return;
			[disposable addDisposable:[[self fileWithURL:url] subscribe:subscriber]];
		}];
		
		return disposable;
	}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)encodingSignal {
	return [[[RACSignal defer:^RACSignal *{
		[self internalLoadFileIfNeeded];
		return RACAbleWithStart(self.encoding);
	}] subscribeOn:fileSystemScheduler()] deliverOn:[RACScheduler currentScheduler]];
}

- (RACDisposable *)bindEncodingToObject:(id)target withKeyPath:(NSString *)keyPath {
	[fileSystemScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	return [target rac_bind:keyPath transformer:^(id value) {
		if (!value || ![value unsignedIntegerValue] || value == [NSNull null]) value = @(NSUTF8StringEncoding);
		return value;
	} onScheduler:[RACScheduler currentScheduler] toObject:self withKeyPath:@keypath(self.encoding) transformer:nil onScheduler:fileSystemScheduler()];
}

- (RACSignal *)contentSignal {
	return [[[RACSignal defer:^RACSignal *{
		[self internalLoadFileIfNeeded];
		return RACAbleWithStart(self.content);
	}] subscribeOn:fileSystemScheduler()] deliverOn:[RACScheduler currentScheduler]];
}

- (RACDisposable *)bindContentToObject:(id)target withKeyPath:(NSString *)keyPath {
	[fileSystemScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	return [target rac_bind:keyPath transformer:^(id value) {
		if (!value || value == [NSNull null]) value = @"";
		return value;
	} onScheduler:[RACScheduler currentScheduler] toObject:self withKeyPath:@keypath(self.content) transformer:nil onScheduler:fileSystemScheduler()];
}

- (RACSignal *)save {
	@weakify(self);
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACDisposable *disposable = [RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}];
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
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
	}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (void)internalLoadFileIfNeeded {
	ASSERT_FILE_SYSTEM_SCHEDULER();
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
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		[disposable addDisposable:[RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}]];
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			if (wasDisposed) return;
			NSError *error = nil;
			if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
				[subscriber sendError:error];
				return;
			}
			[self didCreate:url];
			[disposable addDisposable:[[self directoryWithURL:url] subscribe:subscriber]];
		}];
		
		return disposable;
	}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

+ (RACSignal *)filterChildren:(RACSignal *)childrenSignal byAbbreviation:(RACSignal *)abbreviationSignal {
	return [[RACSignal combineLatest:@[ childrenSignal, abbreviationSignal ?: [RACSignal return:nil]] reduce:^(NSArray *content, NSString *abbreviation) {
		// No abbreviation, no need to filter
		if (![abbreviation length]) {
			return [RACSignal return:[content.rac_sequence.eagerSequence map:^id(id value) {
				return [RACTuple tupleWithObjects:value, nil];
			}].array];
		}
		
		return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
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
					if (wasDisposed) return;
					NSArray *filteredContent = [[[RACSequence zip:@[ content.rac_sequence.eagerSequence, urls.rac_sequence.eagerSequence ]] map:^id(RACTuple *value) {
						RACTupleUnpack(FileSystemItem *item, NSURL *url) = value;
						if (wasDisposed) return [RACTuple tupleWithObjects:item, RACTupleNil.tupleNil, @0, nil];
						NSIndexSet *hitMask = nil;
						float score = [[url lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
						return [RACTuple tupleWithObjects:item, hitMask ? : RACTupleNil.tupleNil, @(score), nil];
					}] filter:^BOOL(RACTuple *item) {
						if (wasDisposed) return NO;
						return [item.third floatValue] > 0;
					}].array;
					if (wasDisposed) return;
					NSArray *sortedContent = [filteredContent sortedArrayUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
						if (wasDisposed) return NSOrderedSame;
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
					if (wasDisposed) return;
					[subscriber sendNext:sortedContent];
					[subscriber sendCompleted];
				} error:^(NSError *error) {
					[subscriber sendError:error];
				} completed:^{
					[subscriber sendCompleted];
				}];
			}];
			
			return disposable;
		}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
	}] switch];
}

- (RACSignal *)children {
	return [self childrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options {
	ASSERT(!(options & NSDirectoryEnumerationSkipsPackageDescendants) && "FileSystemDirectory doesn't support NSDirectoryEnumerationSkipsPackageDescendants");
	@weakify(self);
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		__block BOOL wasDisposed = NO;
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		[disposable addDisposable:[RACDisposable disposableWithBlock:^{
			wasDisposed = YES;
		}]];
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			@strongify(self);
			if (wasDisposed) return;
			RACReplaySubject *childrenBacking = self.childrenBacking;
			if (!childrenBacking) {
				childrenBacking = [RACReplaySubject replaySubjectWithCapacity:1];
				self.childrenBacking = childrenBacking;
				[self didChangeChildren];
			}
			RACSignal *result = childrenBacking;
			
			// Filter out hidden files if needed
			if (options & NSDirectoryEnumerationSkipsHiddenFiles) {
				result = [[result map:^RACSignal *(NSArray *x) {
					if (wasDisposed) return [RACSignal return:@[]];
					if (!x.count) {
						return [RACSignal return:x];
					}
					NSMutableArray *namedItems = [[NSMutableArray alloc] init];
					for (FileSystemItem *item in x) {
						if (wasDisposed) break;
						[namedItems addObject:[item.name map:^RACTuple *(NSString *x) {
							return [RACTuple tupleWithObjectsFromArray:@[item, x ? : [RACTupleNil tupleNil]]];
						}]];
					}
					return [[RACSignal combineLatest:namedItems] map:^NSArray *(RACTuple *xs) {
						if (wasDisposed) return @[];
						NSMutableArray *nonHiddenItems = [[NSMutableArray alloc] init];
						for (RACTuple *namedItem in xs) {
							if (wasDisposed) break;
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
					if (wasDisposed) return [RACSignal return:@[]];
					if (!x.count) {
						return [RACSignal return:x];
					}
					NSMutableArray *descendantSignals = [[NSMutableArray alloc] init];
					for (FileSystemItem *item in x) {
						if (wasDisposed) break;
						[descendantSignals addObject:[[item.type map:^(NSString *type) {
							if (wasDisposed) return RACSignal.empty;
							if (type != NSURLFileResourceTypeDirectory) {
								return [RACSignal return:@[ item ]];
							} else {
								FileSystemDirectory *directory = (FileSystemDirectory *)item;
								return [[directory childrenWithOptions:options] map:^NSArray *(NSArray *x) {
									if (wasDisposed) return @[];
									return [@[ item ] arrayByAddingObjectsFromArray:x];
								}];
							}
						}] switch]];
					}
					return [[RACSignal combineLatest:descendantSignals] map:^NSArray *(RACTuple *xs) {
						if (wasDisposed) return @[];
						NSMutableArray *mergedDescendants = [[NSMutableArray alloc] init];
						for (NSArray *children in xs) {
							if (wasDisposed) break;
							[mergedDescendants addObjectsFromArray:children];
						}
						return mergedDescendants;
					}];
				}] switch];
			}
			
			[disposable addDisposable:[result subscribe:subscriber]];
		}];
		
		return disposable;
	}] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (void)didChangeChildren {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	RACSubject *childrenBacking = self.childrenBacking;
	if (!childrenBacking) return;
	NSURL *url = self.urlBacking.first;
	if (!url) {
		[childrenBacking sendNext:nil];
	}
	NSMutableArray *childrenURLs = [NSMutableArray array];
	for (NSURL *childURL in [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:@[NSURLFileResourceTypeKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
		[childrenURLs addObject:childURL];
	}
	[[RACSignal zip:[childrenURLs.rac_sequence.eagerSequence map:^id(NSURL *childURL) {
		return [FileSystemItem itemWithURL:childURL type:nil];
	}]] subscribeNext:^(RACTuple *children) {
		[childrenBacking sendNext:children.allObjects];
	}];
}

@end

@implementation FileSystemItem (FileManagement)

- (RACSignal *)moveTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)moveTo:(FileSystemDirectory *)destination {
	return [self moveTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)copyTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)copyTo:(FileSystemDirectory *)destination {
	return [self copyTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)renameTo:(NSString *)newName {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)duplicate {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)exportTo:(NSURL *)destination copy:(BOOL)copy {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (RACSignal *)delete {
	RACReplaySubject *result = [RACReplaySubject replaySubjectWithCapacity:1];
	@weakify(self);
	[fileSystemScheduler() schedule:^{
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
	return [result deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

@end

@implementation FileSystemItem (FileManagement_Private)

+ (void)didMove:(NSURL *)source to:(NSURL *)destination {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	FileSystemItem *item = fsItemCache()[source];
	if (item != nil) {
		[item.urlBacking sendNext:destination];
		[fsItemCache() removeObjectForKey:source];
		fsItemCache()[destination] = item;
	}
	NSURL *sourceParent = source.URLByDeletingLastPathComponent;
	NSURL *destinationParent = destination.URLByDeletingLastPathComponent;
	if (![sourceParent isEqual:destinationParent]) {
		[fsItemCache()[sourceParent] didChangeChildren];
		[fsItemCache()[destinationParent] didChangeChildren];
	}
}

+ (void)didCopy:(NSURL *)source to:(NSURL *)destination {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	[fsItemCache()[destination.URLByDeletingLastPathComponent] didChangeChildren];
}

+ (void)didCreate:(NSURL *)target {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	[fsItemCache()[target.URLByDeletingLastPathComponent] didChangeChildren];
}

+ (void)didDelete:(NSURL *)target {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	FileSystemItem *item = fsItemCache()[target];
	if (item) {
		[fsItemCache() removeObjectForKey:target];
		NSString *itemType = item.typeBacking.first;
		[item.urlBacking sendNext:nil];
		[item.typeBacking sendNext:nil];
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
		ASSERT_FILE_SYSTEM_SCHEDULER();
		@strongify(self);
		if (!self || !self.urlBacking.first) {
			return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
		}
		return [self extendedAttributeBackingForKey:key];
	}] subscribeOn:fileSystemScheduler()] deliverOnCurrentSchedulerIfNotFileSystemScheduler];
}

- (id<RACSubscriber>)extendedAttributeSinkForKey:(NSString *)key {
	RACSubject *sink = [RACSubject subject];
	[[sink deliverOn:fileSystemScheduler()] subscribeNext:^(id x) {
		ASSERT_FILE_SYSTEM_SCHEDULER();
		[[self extendedAttributeBackingForKey:key] sendNext:x];
	}];
	return sink;
}

@end

@implementation FileSystemItem (ExtendedAttributes_Private)

- (RACReplaySubject *)extendedAttributeBackingForKey:(NSString *)key {
	ASSERT_FILE_SYSTEM_SCHEDULER();
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
		[[backing deliverOn:fileSystemScheduler()] subscribeNext:^(id x) {
			ASSERT_FILE_SYSTEM_SCHEDULER();
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

@implementation RACSignal (FileSystemItem)

- (RACSignal *)deliverOnCurrentSchedulerIfNotFileSystemScheduler {
	if (currentScheduler() == fileSystemScheduler()) {
		return self;
	} else {
		return [self deliverOn:currentScheduler()];
	}
}

@end
