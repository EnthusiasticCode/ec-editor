//
//  FileSystemFile.m
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemFile.h"
#import "FileSystemItem+Private.h"

@interface FileSystemFile ()

@property (nonatomic) NSStringEncoding encodingBacking;
@property (nonatomic, strong) NSString *contentBacking;
@property (nonatomic, getter = isLoaded) BOOL loaded;

- (void)loadFileIfNeeded;

@end

@implementation FileSystemFile

#pragma mark FileSystemItem

- (instancetype)initWithURL:(NSURL *)url {
	self = [super initWithURL:url];
	if (self == nil) return nil;
	
	_encodingBacking = NSUTF8StringEncoding;
	_contentBacking = @"";
	
	return self;
}

- (RACSignal *)create {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			IF_CANCELLED_RETURN();
			
			@strongify(self);
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if (![NSFileManager.defaultManager fileExistsAtPath:url.path] || ![self.contentBacking writeToURL:url atomically:NO encoding:self.encodingBacking error:&error]) {
				[subscriber sendError:error];
			} else {
				self.loaded = YES;
				[self didCreate];
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}]];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

#pragma mark FileSystemFile

- (RACPropertySubject *)encoding {
	@weakify(self);
	RACPropertySubject *encoding = [RACPropertySubject property];
	RACBinding *encodingBinding = encoding.binding;
	RACScheduler *callingScheduler = currentScheduler();
	
	[fileSystemScheduler() schedule:^{
		@strongify(self);
		[self loadFileIfNeeded];
		RACBinding *encodingBackingBinding = RACBind(self.encodingBacking);
		[[encodingBackingBinding deliverOn:callingScheduler] subscribe:encodingBinding];
		[callingScheduler schedule:^{
			[[[encodingBinding deliverOn:fileSystemScheduler()] map:^(NSNumber *encoding) {
				if (encoding == nil || encoding.unsignedIntegerValue == 0) encoding = @(NSUTF8StringEncoding);
				return encoding;
			}] subscribe:encodingBackingBinding];
		}];
	}];
	
	return encoding;
}

- (RACPropertySubject *)content {
	@weakify(self);
	RACPropertySubject *content = [RACPropertySubject property];
	RACBinding *contentBinding = content.binding;
	RACScheduler *callingScheduler = currentScheduler();
	
	[fileSystemScheduler() schedule:^{
		@strongify(self);
		[self loadFileIfNeeded];
		RACBinding *contentBackingBinding = RACBind(self.contentBacking);
		[[contentBackingBinding deliverOn:callingScheduler] subscribe:contentBinding];
		[callingScheduler schedule:^{
			[[[contentBinding deliverOn:fileSystemScheduler()] filter:^BOOL(NSString *content) {
				return content != nil;
			}] subscribe:contentBackingBinding];
		}];
	}];
	
	return content;
}

- (RACSignal *)save {
	@weakify(self);
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			IF_CANCELLED_RETURN();
			
			@strongify(self);
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if (!url) {
				[subscriber sendError:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
				return;
			}

			IF_CANCELLED_RETURN();
			
			// Don't save atomically so we don't lose extended attributes
			if (![self.contentBacking writeToURL:url atomically:NO encoding:self.encodingBacking error:&error]) {
				[subscriber sendError:error];
			} else {
				[subscriber sendNext:self];
				[subscriber sendCompleted];
			}
		}]];
		
		return disposable;
	}] deliverOn:RACScheduler.currentScheduler];
}

#pragma mark Private Methods

- (void)loadFileIfNeeded {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	if (self.loaded) return;
	NSStringEncoding encoding;
	self.contentBacking = [NSString stringWithContentsOfURL:self.urlBacking usedEncoding:&encoding error:NULL];
	self.encodingBacking = encoding;
	self.loaded = YES;
}

@end
