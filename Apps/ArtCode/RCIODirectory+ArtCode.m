//
//  RCIODirectory+ArtCode.m
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import "RCIODirectory+ArtCode.h"

#import "RCIOFile+ArtCode.h"

static NSString * const labelColorKey = @"com.enthusiasticcode.artcode.LabelColor";
static NSString * const newlyCreatedKey = @"com.enthusiasticcode.artcode.NewlyCreated";

@implementation RCIODirectory (ArtCode)

- (RACPropertySubject *)labelColorSubject {
	return [self extendedAttributeSubjectForKey:labelColorKey];
}

- (RACPropertySubject *)newlyCreatedSubject {
	return [self extendedAttributeSubjectForKey:newlyCreatedKey];
}

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
