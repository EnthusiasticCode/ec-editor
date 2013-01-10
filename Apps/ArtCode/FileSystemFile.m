//
//  FileSystemFile.m
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemFile.h"

@interface FileSystemFile ()

@property (nonatomic) NSStringEncoding encoding;
@property (nonatomic, strong) NSString *content;

- (void)internalLoadFileIfNeeded;

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
	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
	[fileSystemScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	RACBinding *targetBinding = [[target rac_propertyForKeyPath:keyPath] binding];
	RACScheduler *targetBindingScheduler = currentScheduler();
	[fileSystemScheduler() schedule:^{
		RACBinding *encoding = RACBind(self.encoding);
		[disposable addDisposable:[[[targetBinding deliverOn:fileSystemScheduler()] map:^id(NSNumber *value) {
			if (value == nil || value.unsignedIntegerValue == 0 || value == (id)[NSNull null]) value = @(NSUTF8StringEncoding);
			return value;
		}] subscribe:encoding]];
		[disposable addDisposable:[[encoding deliverOn:targetBindingScheduler] subscribe:targetBinding]];
	}];
	return disposable;
}

- (RACSignal *)contentSignal {
	return [[[RACSignal defer:^RACSignal *{
		[self internalLoadFileIfNeeded];
		return RACAbleWithStart(self.content);
	}] subscribeOn:fileSystemScheduler()] deliverOn:[RACScheduler currentScheduler]];
}

- (RACDisposable *)bindContentToObject:(id)target withKeyPath:(NSString *)keyPath {
	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
	[fileSystemScheduler() schedule:^{
		[self internalLoadFileIfNeeded];
	}];
	RACBinding *targetBinding = [[target rac_propertyForKeyPath:keyPath] binding];
	RACScheduler *targetBindingScheduler = currentScheduler();
	[fileSystemScheduler() schedule:^{
		RACBinding *content = RACBind(self.content);
		[disposable addDisposable:[[[targetBinding deliverOn:fileSystemScheduler()] filter:^ BOOL (NSString *value) {
			return value != nil && value != (id)[NSNull null];
		}] subscribe:content]];
		[disposable addDisposable:[[content deliverOn:targetBindingScheduler] subscribe:targetBinding]];
	}];
	return disposable;
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
