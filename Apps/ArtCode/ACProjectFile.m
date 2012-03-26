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
#import "TMSyntaxNode.h"
#import "TMUnit+Internal.h"


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

@implementation ACProjectFile {
    NSMutableDictionary *_bookmarks;
    NSUInteger _openCount;
}

@synthesize fileSize = _fileSize, explicitFileEncoding = _explicitFileEncoding, fileEncoding = _fileEncoding, explicitSyntaxIdentifier = _explicitSyntaxIdentifier, codeFile = _codeFile, syntax = _syntax, codeUnit = _codeUnit;

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
    if (self.explicitSyntaxIdentifier) {
        [plist setObject:self.explicitSyntaxIdentifier forKey:_plistExplicitSyntaxKey];
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

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent fileURL:(NSURL *)fileURL {
    self = [super initWithProject:project propertyListDictionary:plistDictionary parent:parent fileURL:fileURL];
    if (!self) {
        return nil;
    }
    
    // Make sure the file exists
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:fileURL.path]) {
        if (![@"" writeToURL:fileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
            return nil;
        }
    }
    
    NSNumber *fileSize = nil;
    [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    _fileSize = [fileSize unsignedIntegerValue];
    _explicitFileEncoding = [plistDictionary objectForKey:_plistFileEncodingKey];
    _fileEncoding = NSUTF8StringEncoding;
    _explicitSyntaxIdentifier = [plistDictionary objectForKey:_plistExplicitSyntaxKey];
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
    return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
    if (![super readFromURL:url error:error]) {
        return NO;
    }
    // Make sure the file exists
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:self.fileURL.path]) {
        if (![@"" writeToURL:self.fileURL atomically:NO encoding:NSUTF8StringEncoding error:error]) {
            return NO;
        }
    }
    
    NSNumber *fileSize = nil;
    if (![self.fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:error]) {
        return NO;
    };
    _fileSize = [fileSize unsignedIntegerValue];
    return YES;
}

#pragma mark - File metadata

- (NSStringEncoding)fileEncoding {
    if (_explicitFileEncoding) {
        return [_explicitFileEncoding unsignedIntegerValue];
    }
    return NSUTF8StringEncoding;
}

- (NSString *)syntaxIdentifier {
    if (_explicitSyntaxIdentifier) {
        return _explicitSyntaxIdentifier;
    }
    return _syntax.scopeName;
}

#pragma mark - Accessing the content

- (void)openWithCompletionHandler:(void (^)(NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (_openCount) {
        completionHandler(nil);
        return;
    }
    NSStringEncoding encoding = self.fileEncoding;
    NSString *syntaxIdentifier = self.syntaxIdentifier;
    NSString *fileName = self.name;
    [self.project performAsynchronousFileAccessUsingBlock:^{
        NSString *fileContents = [NSString stringWithContentsOfURL:self.fileURL encoding:encoding error:NULL];
        if (fileContents) {
            TMSyntaxNode *syntax = nil;
            if (syntaxIdentifier) {
                syntax = [TMSyntaxNode syntaxWithScopeIdentifier:syntaxIdentifier];
            }
            if (!syntax) {
                syntax = [TMSyntaxNode syntaxForFileName:fileName];
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                _codeFile = CodeFile.alloc.init;
                [_codeFile replaceCharactersInRange:NSMakeRange(0, 0) withString:fileContents];
                _syntax = syntax;
                if (!_syntax) {
                    NSRange firstLineRange = [_codeFile lineRangeForRange:NSMakeRange(0, 0)];
                    NSString *firstLine = [_codeFile stringInRange:firstLineRange];
                    if (firstLine) {
                        _syntax = [TMSyntaxNode syntaxForFirstLine:firstLine];
                    }
                }
                if (_syntax) {
                    _codeUnit = [TMUnit.alloc initWithProjectFile:self];
                }
                completionHandler(nil);
            }];
        } else {
            completionHandler(NSError.alloc.init);
        }
    }];
}

- (void)closeWithCompletionHandler:(void (^)(NSError *))completionHandler {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if (!_openCount) {
        if (completionHandler) {
            completionHandler([[NSError alloc] init]);
        }
        return;
    }
    --_openCount;
    if (_openCount) {
        if (completionHandler) {
            completionHandler(nil);
        }
        return;
    }
    ASSERT(_codeFile);
    NSString *fileContents = _codeFile.string;
    NSStringEncoding encoding = self.fileEncoding;
    __block NSError *error = nil;
    [self.project performAsynchronousFileAccessUsingBlock:^{
        [fileContents writeToURL:self.fileURL atomically:YES encoding:encoding error:&error];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _codeFile = nil;
            _syntax = nil;
            _codeUnit = nil;
            if (completionHandler) {
                completionHandler(error);
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

@end
