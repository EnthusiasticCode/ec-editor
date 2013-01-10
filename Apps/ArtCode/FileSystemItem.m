//
//  FileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem+Private.h"

#import <libkern/OSAtomic.h>
#import <sys/xattr.h>

#import "FileSystemDirectory+Private.h"
#import "FileSystemFile.h"
#import "NSString+ScoreForAbbreviation.h"

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
static NSMutableDictionary *fileSystemItemCache() {
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
			FileSystemItem *item = fileSystemItemCache()[url];
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
			fileSystemItemCache()[url] = item;
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
	}] switchToLatest];
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
	FileSystemItem *item = fileSystemItemCache()[source];
	if (item != nil) {
		[item.urlBacking sendNext:destination];
		[fileSystemItemCache() removeObjectForKey:source];
		fileSystemItemCache()[destination] = item;
	}
	NSURL *sourceParent = source.URLByDeletingLastPathComponent;
	NSURL *destinationParent = destination.URLByDeletingLastPathComponent;
	if (![sourceParent isEqual:destinationParent]) {
		[fileSystemItemCache()[sourceParent] didChangeChildren];
		[fileSystemItemCache()[destinationParent] didChangeChildren];
	}
}

+ (void)didCopy:(NSURL *)source to:(NSURL *)destination {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	[fileSystemItemCache()[destination.URLByDeletingLastPathComponent] didChangeChildren];
}

+ (void)didCreate:(NSURL *)target {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	[fileSystemItemCache()[target.URLByDeletingLastPathComponent] didChangeChildren];
}

+ (void)didDelete:(NSURL *)target {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	FileSystemItem *item = fileSystemItemCache()[target];
	[fileSystemItemCache() removeObjectForKey:target];
	[item didDelete];
	[item.urlBacking sendNext:nil];
	[item.typeBacking sendNext:nil];
		
		NSString *itemType = item.typeBacking.first;
		if (itemType == NSURLFileResourceTypeRegular) {
			((FileSystemFile *)item).content = nil;
		} else if (itemType == NSURLFileResourceTypeDirectory) {
			[((FileSystemDirectory *)item).childrenBacking sendNext:nil];
			NSString *targetString = target.standardizedURL.absoluteString;
			NSArray *keys = fileSystemItemCache().allKeys.copy;
			for (NSURL *key in keys) {
				if ([key.standardizedURL.absoluteString hasPrefix:targetString]) {
					[self didDelete:key];
				}
			}
		}
	}
	[fileSystemItemCache()[[target URLByDeletingLastPathComponent]] didChangeChildren];
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
