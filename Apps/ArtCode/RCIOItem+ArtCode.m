//
//  RCIOItem+ArtCode.m
//  ArtCode
//
//  Created by Uri Baghin on 04/02/2013.
//
//

#import "RCIOItem+ArtCode.h"

#import "RCIOFile+ArtCode.h"

@implementation RCIOItem (ArtCodeBookmarks)

- (RACSignal *)bookmarksSignal {
	return RACSignal.empty;
}

@end

@implementation RCIOFile (ArtCodeBookmarks)

- (RACSignal *)bookmarksSignal {
	return [self.bookmarksSubject map:^(NSIndexSet *bookmarkedLines) {
		return @[ [RACTuple tupleWithObjects:self, bookmarkedLines, nil ] ];
	}];
}

@end

@implementation RCIODirectory (ArtCodeBookmarks)

- (RACSignal *)bookmarksSignal {
	return [[[[self.childrenSignal deliverOn:[RACScheduler scheduler]] map:^(NSArray *children) {
		if (children.count == 0) return [RACSignal return:@[]];
		
		NSMutableArray *childrenBookmarkSignals = [NSMutableArray arrayWithCapacity:children.count];
		
		for (RCIOItem *child in children) {
			if ([child isKindOfClass:RCIODirectory.class]) {
				RCIODirectory *childDirectory = (RCIODirectory *)child;
				[childrenBookmarkSignals addObject:childDirectory.bookmarksSignal];
				continue;
			}
			RCIOFile *childFile = (RCIOFile *)child;
			[childrenBookmarkSignals addObject:[childFile.bookmarksSubject map:^(NSIndexSet *bookmarkedLines) {
				if (bookmarkedLines == nil) return @[];
				return @[ [RACTuple tupleWithObjects:childFile, bookmarkedLines, nil ] ];
			}]];
		}
		
		return [[RACSignal combineLatest:childrenBookmarkSignals] map:^(RACTuple *bookmarkArrays) {
			NSMutableArray *mergedBookmarks = [NSMutableArray array];
			for (NSArray *bookmarkArray in bookmarkArrays) {
				[mergedBookmarks addObjectsFromArray:bookmarkArray];
			}
			return mergedBookmarks;
		}];
	}] switchToLatest] deliverOn:RACScheduler.currentScheduler];
}

@end