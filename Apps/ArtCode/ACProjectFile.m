//
//  ACProjectFile.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectItem+Internal.h"

#import "ACProject.h"
#import "ACProjectFolder.h"

#import "ACProjectFileBookmark.h"

#import "CodeFile.h"
#import <objc/runtime.h>


static NSString * const _plistFileEncodingKey = @"fileEncoding";
static NSString * const _plistExplicitSyntaxKey = @"explicitSyntax";
static NSString * const _plistBookmarksKey = @"bookmarks";

/// Project internal methods to manage bookarks
@interface ACProject (Bookmarks)

- (void)didAddBookmark:(ACProjectFileBookmark *)bookmark;
- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

@end

#pragma mark -

/// Bookmark internal initialization for creation
@interface ACProjectFileBookmark (Internal)

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary file:(ACProjectFile *)file bookmarkPoint:(id)bookmarkPoint;

@end

#pragma mark -

/// Proxy for CodeFile
@interface CodeFileProxy : NSObject
+ (id)newProxyWithTarget:(CodeFile *)target owner:(ACProjectFile *)owner;
@end

@interface ACProjectFile ()
- (void)_codeFileProxyDidDealloc;
@end

@implementation ACProjectFile {
    NSMutableDictionary *_bookmarks;
    
    __weak CodeFileProxy *_codeFileProxy;
    CodeFile *_codeFile;
    NSMutableArray *_pendingCodeFileCompletionHandlers;
}

@synthesize fileEncoding = _fileEncoding, codeFileExplicitSyntaxIdentifier = _codeFileExplicitSyntaxIdentifier, fileSize = _fileSize;

#pragma mark - ACProjectItem

- (ACProjectItemType)type {
    return ACPFile;
}

- (void)remove {
    for (ACProjectFileBookmark *bookmark in _bookmarks.allValues) {
        [bookmark remove];
    }
    [super remove];
}

#pragma mark - ACProjectItem Internal

- (NSDictionary *)propertyListDictionary {
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:[NSNumber numberWithUnsignedInteger:self.fileEncoding] forKey:_plistFileEncodingKey];
    if (self.codeFileExplicitSyntaxIdentifier) {
        [plist setObject:self.codeFileExplicitSyntaxIdentifier forKey:_plistExplicitSyntaxKey];
    }
    NSMutableDictionary *bookmarks = [[NSMutableDictionary alloc] init];
    [_bookmarks enumerateKeysAndObjectsUsingBlock:^(id point, ACProjectFileBookmark *bookmark, BOOL *stop) {
        if ([point isKindOfClass:[NSNumber class]]) {
            point = [(NSNumber *)point stringValue];
        }
        ASSERT([point isKindOfClass:[NSString class]]);
        [bookmarks setObject:bookmark.propertyListDictionary forKey:point];
    }];
    [plist setObject:bookmarks forKey:_plistBookmarksKey];
    return plist;
}

#pragma mark - ACProjectFileSystemItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL originalURL:(NSURL *)originalURL {
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent fileURL:fileURL originalURL:originalURL];
    if (!self) {
        return nil;
    }
    NSNumber *fileSize = nil;
    [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    _fileSize = [fileSize unsignedIntegerValue];
    _fileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey] ? [[plistDictionary objectForKey:_plistFileEncodingKey] unsignedIntegerValue] : NSUTF8StringEncoding;
    _codeFileExplicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
    _bookmarks = [[NSMutableDictionary alloc] init];
    [[plistDictionary objectForKey:_plistBookmarksKey] enumerateKeysAndObjectsUsingBlock:^(id point, NSDictionary *bookmarkPlist, BOOL *stop) {
        NSScanner *scanner = [NSScanner scannerWithString:point];
        NSInteger line;
        if ([scanner scanInteger:&line])
            point = [NSNumber numberWithInteger:line];
        ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:project propertyListDictionary:bookmarkPlist file:self bookmarkPoint:point];
        if (!bookmark)
            return;
        [_bookmarks setObject:bookmark forKey:point];
        [project didAddBookmark:bookmark];
    }];
    _pendingCodeFileCompletionHandlers = [[NSMutableArray alloc] init];
    return self;
}

#pragma mark - Accessing the content

- (void)openCodeFileWithCompletionHandler:(void (^)(CodeFile *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    
    // If we already have a proxy, 
    if (_codeFileProxy && completionHandler) {
        return completionHandler((CodeFile *)_codeFileProxy);
    }
    
    // Queue up the completion handler so it gets executed even this method is called multiple times
    if (completionHandler) {
        [_pendingCodeFileCompletionHandlers addObject:completionHandler];
    }
    
    // If we have a codeFile, but we don't have a proxy, it means there's an open OR close operation in flight
    if (_codeFile) {
        return;
    }
    
    [self.project performAsynchronousFileAccessUsingBlock:^{
        _codeFile = [[CodeFile alloc] initWithFileURL:self.fileURL];
        [_codeFile openWithCompletionHandler:^(BOOL success) {
            if (success) {
                CodeFileProxy *proxy = [CodeFileProxy newProxyWithTarget:_codeFile owner:self];
                _codeFileProxy = proxy;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    for (void(^pendingCompletionHandler)(CodeFile *) in _pendingCodeFileCompletionHandlers)
                        pendingCompletionHandler((CodeFile *)proxy);
                }];
                [_pendingCodeFileCompletionHandlers removeAllObjects];
            } else {
                // Open failed, passing nil to pending completion handlers
                _codeFile = nil;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    for (void(^pendingCompletionHandler)(CodeFile *) in _pendingCodeFileCompletionHandlers)
                        pendingCompletionHandler(nil);
                }];
                [_pendingCodeFileCompletionHandlers removeAllObjects];
            }
        }];
    }];
}

#pragma mark - Managing file bookmarks

- (NSArray *)bookmarks {
    return [_bookmarks allValues];
}

- (void)addBookmarkWithPoint:(id)point {
    ACProjectFileBookmark *bookmark = [[ACProjectFileBookmark alloc] initWithProject:self.project propertyListDictionary:nil file:self bookmarkPoint:point];
    [_bookmarks setObject:bookmark forKey:point];
    [self.project didAddBookmark:bookmark];
    [self.project updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Internal Methods

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark {
    [self willChangeValueForKey:@"bookmarks"];
    [_bookmarks removeObjectForKey:bookmark.bookmarkPoint];
    [self.project didRemoveBookmark:bookmark];
    [self didChangeValueForKey:@"bookmarks"];
}

#pragma mark - Private Methods

- (void)_codeFileProxyDidDealloc {
    ASSERT(!_codeFileProxy && _codeFile);
    [_codeFile closeWithCompletionHandler:^(BOOL success) {
        _codeFile = nil;
        if (_pendingCodeFileCompletionHandlers.count)
            [self openCodeFileWithCompletionHandler:nil];
    }];
}

@end

#pragma mark -

@implementation CodeFileProxy {
    CodeFile *_target;
    ACProjectFile *_owner;
}

+ (id)newProxyWithTarget:(CodeFile *)target owner:(ACProjectFile *)owner {
    ASSERT(target && owner);
    CodeFileProxy *proxy = [self alloc];
    proxy->_target = target;
    proxy->_owner = owner;
    return proxy;
}

- (void)dealloc {
    [_owner _codeFileProxyDidDealloc];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    Method method = class_getClassMethod([CodeFile class], sel);
    if (!method) {
        return NO;
    }
    Class metaClass = objc_getMetaClass("CodeFileProxy");
    class_addMethod(metaClass, sel, method_getImplementation(method), method_getTypeEncoding(method));
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    ASSERT(_target);
    return _target;
}

@end
