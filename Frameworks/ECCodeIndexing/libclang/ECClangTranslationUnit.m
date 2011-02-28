//
//  ECClangTranslationUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangTranslationUnit.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ECClangTranslationUnit

@synthesize translationUnit = _translationUnit;
@synthesize file = _file;

- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options
{
    self = [super init];
    if (!self)
        return nil;
    int parameter_count = 10;
    const char *filePath = [[file path] fileSystemRepresentation];
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    self.translationUnit = clang_parseTranslationUnit(index, filePath, parameters, parameter_count, 0, 0, CXTranslationUnit_PrecompiledPreamble | CXTranslationUnit_CacheCompletionResults);
    self.file = file;
    return self;
}

+ (id)translationUnitWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options
{
    id translationUnit = [self alloc];
    translationUnit = [translationUnit initWithFile:file index:index options:options];
    return [translationUnit autorelease];
}

@end
