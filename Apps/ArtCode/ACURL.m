//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURL.h"

NSString * const ACProjectBundleExtension = @"acproj";
NSString * const ACURLScheme = @"artcode";

@implementation NSURL (ACURL)

+ (NSURL *)applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

+ (NSURL *)applicationLibraryDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

- (BOOL)isACURL
{
    return [self.scheme isEqualToString:ACURLScheme];
}

- (NSURL *)ACProjectURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:/%@", ACURLScheme, [self.pathComponents objectAtIndex:1]]];
}

- (NSString *)ACProjectName
{
    ECASSERT([self isACURL]);
    return [[self.pathComponents objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSURL *)ACURLWithPathComponents:(NSArray *)pathComponents
{
    ECASSERT(pathComponents);
    ECASSERT([pathComponents count]);
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@:/%@", ACURLScheme, [[pathComponents componentsJoinedByString:@"/"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

+ (NSURL *)ACURLWithPath:(NSString *)path
{
    ECASSERT(path);
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
