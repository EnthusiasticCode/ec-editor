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

- (NSString *)ACProjectName
{
    ECASSERT([self.scheme isEqualToString:ACURLScheme]);
    return [[self.pathComponents objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL *)ACProjectBundleURL
{
    return [[[[self class] applicationDocumentsDirectory] URLByAppendingPathComponent:[self ACProjectName]] URLByAppendingPathExtension:ACProjectBundleExtension];
}

- (NSURL *)ACProjectContentURL
{
    return [[[[[self class] applicationDocumentsDirectory] URLByAppendingPathComponent:[self ACProjectName]] URLByAppendingPathExtension:ACProjectBundleExtension] URLByAppendingPathComponent:ACProjectContentDirectory isDirectory:YES];
}

+ (NSURL *)ACURLForProjectWithName:(NSString *)name
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
    ECASSERT([[URL scheme] isEqualToString:ACURLScheme]);
    if (![[URL scheme] isEqualToString:ACURLScheme])
        return NO;
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
