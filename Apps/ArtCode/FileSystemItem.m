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

RACScheduler *fileSystemScheduler() {
  static RACScheduler *fileSystemScheduler = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
		fileSystemScheduler = [RACScheduler scheduler];
  });
  return fileSystemScheduler;
}

RACScheduler *currentScheduler() {
	ASSERT(RACScheduler.currentScheduler);
  return RACScheduler.currentScheduler;
}

// Cache of existing FileSystemItems, used for uniquing
NSMutableDictionary *fileSystemItemCache() {
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

@property (nonatomic, strong) NSURL *urlBacking;

@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

@end

@implementation FileSystemItem

+ (RACSignal *)itemWithURL:(NSURL *)url {
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
	}] deliverOn:currentScheduler()];}

- (instancetype)initWithURL:(NSURL *)url {
  ASSERT_FILE_SYSTEM_SCHEDULER();
  self = [super init];
  if (!self) {
    return nil;
  }
  _urlBacking = url;
  _extendedAttributesBacking = [NSMutableDictionary dictionary];
  return self;
}

- (RACSignal *)url {
  return [self.urlBacking deliverOn:currentScheduler()];
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

- (void)didMoveToURL:(NSURL *)url {
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

- (void)didCopyToURL:(NSURL *)url {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	[fileSystemItemCache()[destination.URLByDeletingLastPathComponent] didChangeChildren];
}

- (void)didDelete {
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
			[self didMoveToURL:destinationURL];
			[result sendNext:self];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
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
			[self didCopyToURL:destinationURL];
			[result sendNext:[[self class] itemWithURL:destinationURL type:nil]];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
}

- (RACSignal *)moveTo:(FileSystemDirectory *)destination {
	return [self moveTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)copyTo:(FileSystemDirectory *)destination {
	return [self copyTo:destination withName:nil replaceExisting:YES];
}

- (RACSignal *)renameTo:(NSString *)newName {
	return [self moveTo:nil withName:newName replaceExisting:YES];
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
			[self didCopyToURL:destinationURL];
			[result sendNext:[[self class] itemWithURL:destinationURL type:nil]];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
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
			[self didDelete];
			[result sendNext:self];
			[result sendCompleted];
		}
	}];
	return [result deliverOn:currentScheduler()];
}

@end

@implementation FileSystemItem (ExtendedAttributes)

- (RACPropertySubject *)extendedAttributeForKey:(NSString *)key {
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

