//
//  FileSystemDirectory.m
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemDirectory+Private.h"
#import "FileSystemItem+Private.h"

@interface FileSystemDirectory ()

@property (nonatomic, weak) RACReplaySubject *childrenBacking;

@end

@implementation FileSystemDirectory

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
	}] deliverOn:RACScheduler.currentScheduler];
}

+ (RACSignal *)filterChildren:(RACSignal *)childrenSignal byAbbreviation:(RACSignal *)abbreviationSignal {
	NSParameterAssert(abbreviationSignal != nil);
	return [[RACSignal combineLatest:@[ childrenSignal, abbreviationSignal ] reduce:^(NSArray *content, NSString *abbreviation) {
		// No abbreviation, no need to filter
		if (![abbreviation length]) {
			return [RACSignal return:[content.rac_sequence.eagerSequence map:^id(id value) {
				return [RACTuple tupleWithObjects:value, nil];
			}].array];
		}
		
		return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
			DISPOSED_FLAG_DISPOSABLE(disposable);
			
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
		}];
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
				}] switchToLatest];
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
						}] switchToLatest]];
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
				}] switchToLatest];
			}
			
			[disposable addDisposable:[result subscribe:subscriber]];
		}];
		
		return disposable;
	}] deliverOn:RACScheduler.currentScheduler];
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
