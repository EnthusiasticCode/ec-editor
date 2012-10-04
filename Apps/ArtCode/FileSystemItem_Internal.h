//
//  FileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
@class RACEchoSubject;

@interface FileSystemItem ()

// All filesystem operations and accesses to the FileSystem instances' state must be done on this scheduler
+ (RACScheduler *)fileSystemScheduler;

// Wrap the subscribable so it's run on the fileSystemScheduler
+ (id<RACSubscribable>)coordinateSubscribable:(id<RACSubscribable>)subscribable;

// Returns the item with the given url if it's cached. Used to guarantee uniquing of items
+ (instancetype)cachedItemWithURL:(NSURL *)url;

// Adds \a item to the cache. Cannot be called with items already in the cache.
+ (void)cacheItem:(FileSystemItem *)item;

// Only called / delivers on fileSystemScheduler
- (id<RACSubscribable>)internalItemURL;

// Only called / delivers on fileSystemScheduler
- (id<RACSubscribable>)internalItemType;

// Only called on fileSystemScheduler
- (instancetype)initByReadingItemAtURL:(NSURL *)url;

// Only called on fileSystemScheduler
- (instancetype)initByCreatingItemAtURL:(NSURL *)url;

#pragma mark - Internal state backing and echoes

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSURL *itemURLBacking;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSString *itemTypeBacking;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSData *contentBacking;

// Only called/subscribed/delivers on fileSystemScheduler
@property (nonatomic, strong, readonly) RACEchoSubject *contentEcho;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

// Only called/bound/observed on fileSystemScheduler
// Contained subjects: only called/subscribed/delivers on fileSystemScheduler
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesEchoes;

@end
