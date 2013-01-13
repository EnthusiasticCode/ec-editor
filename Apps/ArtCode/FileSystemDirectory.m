//
//  FileSystemDirectory.m
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemDirectory+Private.h"
#import "FileSystemItem+Private.h"

#import "NSString+ScoreForAbbreviation.h"

@interface FileSystemDirectory ()

@property (nonatomic, strong, readonly) NSArray *childrenBacking;

@end

@implementation FileSystemDirectory {
	NSMutableArray *_childrenBacking;
}

#pragma mark FileSystemItem

- (RACSignal *)create {
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			@strongify(self);
			NSURL *url = self.urlBacking;
			NSError *error = nil;
			
			if (![NSFileManager.defaultManager fileExistsAtPath:url.path] && ![NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
				[subscriber sendError:error];
			} else {
				[disposable addDisposable:[super.create subscribe:subscriber]];
			}
		}]];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

#pragma mark FileSystemDirectory

static void processContent(NSArray *input, NSMutableArray *output, NSDirectoryEnumerationOptions options, volatile uint32_t *cancel) {
	for (FileSystemItem *item in input) {
		// Break out if cancelled
		if (*cancel != 0) break;
		
		// Skip deleted files
		if (item.urlBacking == nil) continue;
		
		// Skip hidden files
		if ((options & NSDirectoryEnumerationSkipsHiddenFiles) && ([item.urlBacking.lastPathComponent characterAtIndex:0] == L'.')) continue;
		
		[output addObject:item];
		
		// Merge in descendants
		if (!(options & NSDirectoryEnumerationSkipsSubdirectoryDescendants) && [item isKindOfClass:FileSystemDirectory.class]) processContent(((FileSystemDirectory *)item).childrenBacking, output, options, cancel);
	}
}

- (RACSignal *)childrenSignalWithOptions:(NSDirectoryEnumerationOptions)options {
	ASSERT(!(options & NSDirectoryEnumerationSkipsPackageDescendants) && "FileSystemDirectory doesn't support NSDirectoryEnumerationSkipsPackageDescendants");
	@weakify(self);
	
	return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		CANCELLATION_DISPOSABLE(disposable);
		
		[disposable addDisposable:[fileSystemScheduler() schedule:^{
			@strongify(self);
			
			[disposable addDisposable:[[RACBind(self.childrenBacking) map:^ NSArray * (NSArray *content) {
				IF_CANCELLED_RETURN(@[]);
				NSMutableArray *processedContent = [NSMutableArray arrayWithCapacity:content.count];
				
				processContent(content, processedContent, options, CANCELLATION_FLAG);
				
				return processedContent;
			}] subscribe:subscriber]];
		}]];
		
		return disposable;
	}] deliverOn:currentScheduler()];
}

- (RACSignal *)childrenSignal {
	return [self childrenSignalWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
}

- (void)didAddItem:(FileSystemItem *)item {
	NSParameterAssert(item != nil && ![self.childrenBacking containsObject:item]);
	NSUInteger index = [self.childrenBacking indexOfObject:item inSortedRange:NSMakeRange(0, self.childrenBacking.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(FileSystemItem *item1, FileSystemItem *item2) {
		return [item1.urlBacking.lastPathComponent compare:item2.urlBacking.lastPathComponent];
	}];
	[[self mutableArrayValueForKey:@keypath(self.childrenBacking)] insertObject:item atIndex:index];
}

- (void)didRemoveItem:(FileSystemItem *)item {
	NSParameterAssert(item != nil && [self.childrenBacking containsObject:item]);
	[[self mutableArrayValueForKey:@keypath(self.childrenBacking)] removeObject:item];
}

#pragma mark Private Methods

- (NSArray *)childrenBacking {
	ASSERT_FILE_SYSTEM_SCHEDULER();
	
	if (_childrenBacking == nil) {
		NSURL *url = self.urlBacking;
		if (url == nil) {
			return nil;
		}
		
		_childrenBacking = [NSMutableArray array];
		for (NSURL *childURL in [NSFileManager.defaultManager enumeratorAtURL:url includingPropertiesForKeys:@[NSURLFileResourceTypeKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
			FileSystemItem *child = [self.class loadItemFromURL:childURL];
			if (child != nil) [_childrenBacking addObject:child];
		}
	}
	
	return _childrenBacking;
}

- (NSUInteger)countOfChildrenBacking {
	return _childrenBacking.count;
}

- (FileSystemItem *)objectInChildrenBackingAtIndex:(NSUInteger)index {
	return [_childrenBacking objectAtIndex:index];
}

- (NSArray *)childrenBackingAtIndexes:(NSIndexSet *)indexes {
	return [_childrenBacking objectsAtIndexes:indexes];
}

- (void)getChildrenBacking:(FileSystemItem * __unsafe_unretained *)buffer range:(NSRange)inRange {
	[_childrenBacking getObjects:buffer range:inRange];
}

- (void)insertObject:(FileSystemItem *)object inChildrenBackingAtIndex:(NSUInteger)index {
	[_childrenBacking insertObject:object atIndex:index];
}

- (void)insertChildrenBacking:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
	[_childrenBacking insertObjects:array atIndexes:indexes];
}

- (void)removeObjectFromChildrenBackingAtIndex:(NSUInteger)index {
	[_childrenBacking removeObjectAtIndex:index];
}

- (void)removeChildrenBackingAtIndexes:(NSIndexSet *)indexes {
	[_childrenBacking removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInChildrenBackingAtIndex:(NSUInteger)index withObject:(FileSystemItem *)object {
	[_childrenBacking replaceObjectAtIndex:index withObject:object];
}

- (void)replaceChildrenBackingAtIndexes:(NSIndexSet *)indexes withChildrenBacking:(NSArray *)array {
	[_childrenBacking replaceObjectsAtIndexes:indexes withObjects:array];
}

@end
