//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCursor.h"
#import "ECClangHelperFunctions.h"

@interface ECClangCodeCursor ()
{
    NSUInteger _hash;
    CXCursor _cursor;
}
- (NSUInteger)computeHash;
@end

@implementation ECClangCodeCursor

@synthesize language = _language;
@synthesize kind = _kind;
@synthesize kindCategory = _kindCategory;
@synthesize spelling = _spelling;
@synthesize fileURL = _fileURL;
@synthesize offset = _offset;
@synthesize extent = _extent;
@synthesize unifiedSymbolResolution = _unifiedSymbolResolution;
@synthesize parent = _parent;

- (NSString *)language
{
    if (!_language)
    {
        enum CXLanguageKind clangLanguage = clang_getCursorLanguage(_cursor);
        switch (clangLanguage) {
            case CXLanguage_C:
                _language = @"C";
                break;
            case CXLanguage_ObjC:
                _language = @"Objective C";
                break;
            case CXLanguage_CPlusPlus:
                _language = @"C++";
                break;
            case CXLanguage_Invalid:
            default:
                _language = @"Unknown";
                break;
        }
    }
    return _language;
}

- (NSString *)spelling
{
    if (!_spelling)
    {
        CXString clangSpelling = clang_getCursorSpelling(_cursor);
        _spelling = [NSString stringWithCString:clang_getCString(clangSpelling) encoding:NSUTF8StringEncoding];
        clang_disposeString(clangSpelling);
    }
    return _spelling;
}

- (NSString *)unifiedSymbolResolution
{
    if (!_unifiedSymbolResolution)
    {
        CXString clangUnifiedSymbolResolution = clang_getCursorUSR(_cursor);
        _unifiedSymbolResolution = [NSString stringWithCString:clang_getCString(clangUnifiedSymbolResolution) encoding:NSUTF8StringEncoding];
        clang_disposeString(clangUnifiedSymbolResolution);
    }
    return _unifiedSymbolResolution;
}

- (ECCodeCursor *)parent
{
    if (!_parent)
        _parent = [[self class] cursorWithCXCursor:clang_getCursorSemanticParent(_cursor)];
    return _parent;
}

- (id)initWithCXCursor:(CXCursor)clangCursor
{
    self = [super init];
    if (!self)
        return nil;
    _cursor = clangCursor;
    _hash = [self computeHash];
    _kind = (ECCodeCursorKind)clang_getCursorKind(_cursor);
    _kindCategory = ECCodeCursorKindCategoryFromClangKind(_kind);
    NSString *filePath;
    ECCodeOffsetAndFileFromClangSourceLocation(clang_getCursorLocation(_cursor), &_offset, &filePath);
    if (filePath)
        _fileURL = [NSURL fileURLWithPath:filePath];
    ECCodeRangeAndFileFromClangSourceRange(clang_getCursorExtent(_cursor), &_extent, NULL);
    return self;
}

+ (id)cursorWithCXCursor:(CXCursor)clangCursor
{
    id cursor = [self alloc];
    cursor = [cursor initWithCXCursor:clangCursor];
    return cursor;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)hash
{
    return _hash;
}

- (NSUInteger)computeHash
{
    return [self.unifiedSymbolResolution hash];
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECClangCodeCursor *otherCursor = other;
    if (self.unifiedSymbolResolution || otherCursor.unifiedSymbolResolution)
        if (![otherCursor.unifiedSymbolResolution isEqualToString:self.unifiedSymbolResolution])
            return NO;
    return YES;
}

- (NSArray *)childCursors
{
    NSMutableArray *childCursors = [NSMutableArray array];
    [self enumerateChildCursorsWithBlock:^ECCodeChildVisitResult(ECCodeCursor *cursor, ECCodeCursor *parent) {
        [childCursors addObject:cursor];
        return ECCodeChildVisitResultContinue;
    }];
    return childCursors;
}

- (void)enumerateChildCursorsWithBlock:(ECCodeChildVisitResult (^)(ECCodeCursor *, ECCodeCursor *))enumerationBlock
{
    clang_visitChildrenWithBlock(_cursor, ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        return enumerationBlock([[self class] cursorWithCXCursor:cursor], [[self class] cursorWithCXCursor:parent]);
    });
}

@end
