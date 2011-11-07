//
//  ClangHelperFunctions.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ClangHelperFunctions.h"

NSUInteger Clang_SourceLocationOffset(CXSourceLocation clangSourceLocation, NSURL *__autoreleasing *fileURL)
{
    if (clang_equalLocations(clangSourceLocation, clang_getNullLocation()))
        return NSNotFound;
    CXFile clangFile;
    unsigned clangOffset;
    clang_getInstantiationLocation(clangSourceLocation, &clangFile, NULL, NULL, &clangOffset);
    if (fileURL)
    {
        CXString clangFileName = clang_getFileName(clangFile);
        if (clang_getCString(clangFileName))
            *fileURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:clang_getCString(clangFileName)]];
        else
            *fileURL = nil;
        clang_disposeString(clangFileName);
    }
    return clangOffset;
}

NSRange Clang_SourceRangeRange(CXSourceRange clangSourceRange, NSURL *__autoreleasing *fileURL)
{
    if (clang_equalRanges(clangSourceRange, clang_getNullRange()))
        return NSMakeRange(NSNotFound, 0);
    NSUInteger start = Clang_SourceLocationOffset(clang_getRangeStart(clangSourceRange), fileURL);
    NSUInteger end = Clang_SourceLocationOffset(clang_getRangeEnd(clangSourceRange), NULL);
    ECASSERT(end > start);
    return NSMakeRange(start, end - start);
}
