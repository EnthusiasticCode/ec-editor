//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSURL+Utilities.h"
#import "NSDictionary+URLAdditions.h"

@interface NSURL (Additions_Internal)
+ (NSArray *)_packageExtensions;
@end

@implementation NSURL (Additions_Internal)

+ (NSArray *)_packageExtensions
{
    static NSArray *packageExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageExtensions = [NSArray arrayWithObjects:@"app", @"tmbundle", @"bundle", nil];
    });
    return packageExtensions;
}

@end

@implementation NSURL (Additions)

+ (NSURL *)applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

+ (NSURL *)applicationLibraryDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

+ (NSURL *)temporaryDirectory
{
    NSURL *temporaryDirectory;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    do
    {
        CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
        CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
        temporaryDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:(__bridge NSString *)uuidString];
        CFRelease(uuidString);
        CFRelease(uuid);
    }
    while ([fileManager fileExistsAtPath:[temporaryDirectory path]]);
    return temporaryDirectory;
}

- (BOOL)isSubdirectoryDescendantOfDirectoryAtURL:(NSURL *)directoryURL
{
    if (![[self absoluteString] hasPrefix:[directoryURL absoluteString]])
        return NO;
    return [[self pathComponents] count] != [[directoryURL pathComponents] count] + 1;
}

- (BOOL)isHidden
{
    return [[self lastPathComponent] characterAtIndex:0] == L'.';
}

- (BOOL)isHiddenDescendant
{
    return !([[[self absoluteString] stringByDeletingLastPathComponent] rangeOfString:@"/."].location == NSNotFound);
}

- (BOOL)isPackage
{
    for (NSString *packageExtension in [[self class] _packageExtensions])
        if ([[self pathExtension] isEqualToString:packageExtension])
            return YES;
    return NO;
}

- (BOOL)isPackageDescendant
{
    NSString *absoluteString = [self absoluteString];
    if ([absoluteString characterAtIndex:[absoluteString length] - 1] == L'/')
        absoluteString = [absoluteString substringToIndex:[absoluteString length] - 1];
    for (NSString *packageExtension in [[self class] _packageExtensions])
    {
        NSRange rangeOfPackageExtension = [absoluteString rangeOfString:[packageExtension stringByAppendingString:@"/"]];
        if (rangeOfPackageExtension.location != NSNotFound)
            return YES;
    }
    return NO;
}

- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number
{
    return [[self URLByDeletingLastPathComponent] URLByAppendingPathComponent:[[[self lastPathComponent] stringByDeletingPathExtension] stringByAppendingFormat:@" (%u).%@", number, [self pathExtension]]];
}

- (NSURL *)URLByAppendingFragmentDictionary:(NSDictionary *)fragmentDictionary
{
    // TODO build the URL in a better way
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@#%@", [self absoluteString], [fragmentDictionary stringWithURLEncodedComponents]]];;
}

- (NSDictionary *)fragmentDictionary
{
    return [NSDictionary dictionaryWithURLEncodedString:self.fragment];
}

@end

@implementation NSURL (FixedIsEqual)

- (BOOL)isEqualToURL:(NSURL *)otherURL
{
	return [[self absoluteURL] isEqual:[otherURL absoluteURL]] || ([self isFileURL] && [otherURL isFileURL] && [[self path] isEqual:[otherURL path]]);
}

@end