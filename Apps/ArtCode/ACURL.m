//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURL.h"

NSString * const ACProjectBundleExtension = @"bundle";
NSString * const ACURLScheme = @"artcode";
NSString * const ACProjectContentDirectory = @"Content";

@implementation NSURL (ACURL)

+ (NSURL *)applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
}

- (BOOL)isACURL
{
    return [self.scheme isEqualToString:ACURLScheme];
}

- (BOOL)isLocal
{
    // all ACURLs are local at the moment
    return YES;
}

+ (NSURL *)ACLocalProjectsDirectory
{
    return [self applicationDocumentsDirectory];
}

- (NSString *)ACProjectName
{
    ECASSERT([self isACURL]);
    return [[self.pathComponents objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)ACProjectBundleURL
{
    ECASSERT([self isACURL]);
    if ([self isLocal])
        return [[[[self class] ACLocalProjectsDirectory] URLByAppendingPathComponent:[self ACProjectName]] URLByAppendingPathExtension:ACProjectBundleExtension];
    else
        ECASSERT(false); // NYI
}

- (NSURL *)ACProjectContentURL
{
    ECASSERT([self isACURL]);
    return [[[[[self class] ACLocalProjectsDirectory] URLByAppendingPathComponent:[self ACProjectName]] URLByAppendingPathExtension:ACProjectBundleExtension] URLByAppendingPathComponent:ACProjectContentDirectory isDirectory:YES];
}

+ (NSURL *)ACURLForLocalProjectWithName:(NSString *)name
{
    ECASSERT(name);
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:/%@", ACURLScheme, [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

+ (NSURL *)ACURLWithPath:(NSString *)path
{
    ECASSERT(path != nil);
    ECASSERT([path hasPrefix:@"/"]);
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", ACURLScheme, [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (BOOL)isAncestorOfACURL:(NSURL *)URL
{
    ECASSERT([self isACURL]);
    NSArray *URLPathComponents = [URL pathComponents];
    NSArray *selfPathComponents = [self pathComponents];
    NSUInteger selfPathComponentsCount = [selfPathComponents count];
    if (selfPathComponentsCount > [URLPathComponents count])
        return NO;
    for (NSUInteger currentPathComponent = 0; currentPathComponent < selfPathComponentsCount; ++currentPathComponent)
        if (![[URLPathComponents objectAtIndex:currentPathComponent] isEqualToString:[selfPathComponents objectAtIndex:currentPathComponent]])
            return NO;
    return YES;
}

- (BOOL)isDescendantOfACURL:(NSURL *)URL
{
    return [URL isAncestorOfACURL:self];
}

@end
