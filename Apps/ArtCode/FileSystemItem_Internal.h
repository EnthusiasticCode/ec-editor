//
//  FileSystemItem_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
@class RACPropertySyncSubject;

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

// RACPropertySyncSubject for NSData content
@property (nonatomic, strong) RACPropertySyncSubject *contentSubject;

// Cache of RACPropertySyncSubjects for NSString contents
@property (nonatomic, strong, readonly) NSMutableDictionary *contentSubjects;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong) NSData *contentBacking;

// Cache of RACPropertySyncSubjects for extended attributes
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributeSubjects;

// Only called/bound/observed on fileSystemScheduler
@property (nonatomic, strong, readonly) NSMutableDictionary *extendedAttributesBacking;

@end
