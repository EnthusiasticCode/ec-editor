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
		CANCELLATION_COMPOUND_DISPOSABLE(disposable);
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			IF_CANCELLED_RETURN();
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
			CANCELLATION_DISPOSABLE(disposable);
			
			[RACScheduler.scheduler schedule:^{
				ASSERT_NOT_MAIN_QUEUE();
				// Filter the content
				[[[RACSignal zip:[content.rac_sequence.eagerSequence map:^(FileSystemItem *item) {
					return item.url;
				}]] take:1] subscribeNext:^(RACTuple *urls) {
					IF_CANCELLED_RETURN();
					NSArray *filteredContent = [[[RACSequence zip:@[ content.rac_sequence.eagerSequence, urls.rac_sequence.eagerSequence ]] map:^id(RACTuple *value) {
						RACTupleUnpack(FileSystemItem *item, NSURL *url) = value;
						IF_CANCELLED_RETURN([RACTuple tupleWithObjects:item, RACTupleNil.tupleNil, @0, nil]);
						NSIndexSet *hitMask = nil;
						float score = [[url lastPathComponent] scoreForAbbreviation:abbreviation hitMask:&hitMask];
						return [RACTuple tupleWithObjects:item, hitMask ? : RACTupleNil.tupleNil, @(score), nil];
					}] filter:^BOOL(RACTuple *item) {
						IF_CANCELLED_RETURN(NO);
						return [item.third floatValue] > 0;
					}].array;
					IF_CANCELLED_RETURN();
					NSArray *sortedContent = [filteredContent sortedArrayUsingComparator:^NSComparisonResult(RACTuple *tuple1, RACTuple *tuple2) {
						IF_CANCELLED_RETURN(NSOrderedSame);
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
					IF_CANCELLED_RETURN();
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
		CANCELLATION_COMPOUND_DISPOSABLE(disposable);
		
		[fileSystemScheduler() schedule:^{
			ASSERT_FILE_SYSTEM_SCHEDULER();
			@strongify(self);
			IF_CANCELLED_RETURN();
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
					IF_CANCELLED_RETURN([RACSignal return:@[]]);
					if (!x.count) {
						return [RACSignal return:x];
					}
					NSMutableArray *namedItems = [[NSMutableArray alloc] init];
					for (FileSystemItem *item in x) {
						IF_CANCELLED_BREAK();
						[namedItems addObject:[item.name map:^RACTuple *(NSString *x) {
							return [RACTuple tupleWithObjectsFromArray:@[item, x ? : [RACTupleNil tupleNil]]];
						}]];
					}
					return [[RACSignal combineLatest:namedItems] map:^NSArray *(RACTuple *xs) {
						IF_CANCELLED_RETURN(@[]);
						NSMutableArray *nonHiddenItems = [[NSMutableArray alloc] init];
						for (RACTuple *namedItem in xs) {
							IF_CANCELLED_BREAK();
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
					IF_CANCELLED_RETURN([RACSignal return:@[]]);
					if (!x.count) {
						return [RACSignal return:x];
					}
					NSMutableArray *descendantSignals = [[NSMutableArray alloc] init];
					for (FileSystemItem *item in x) {
						IF_CANCELLED_BREAK();
						[descendantSignals addObject:[[item.type map:^(NSString *type) {
							IF_CANCELLED_RETURN(RACSignal.empty);
							if (type != NSURLFileResourceTypeDirectory) {
								return [RACSignal return:@[ item ]];
							} else {
								FileSystemDirectory *directory = (FileSystemDirectory *)item;
								return [[directory childrenWithOptions:options] map:^NSArray *(NSArray *x) {
									IF_CANCELLED_RETURN(@[]);
									return [@[ item ] arrayByAddingObjectsFromArray:x];
								}];
							}
						}] switchToLatest]];
					}
					return [[RACSignal combineLatest:descendantSignals] map:^NSArray *(RACTuple *xs) {
						IF_CANCELLED_RETURN(@[]);
						NSMutableArray *mergedDescendants = [[NSMutableArray alloc] init];
						for (NSArray *children in xs) {
							IF_CANCELLED_BREAK();
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
