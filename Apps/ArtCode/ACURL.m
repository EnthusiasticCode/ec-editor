//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACURL.h"
#import "NSURL+SSToolkitAdditions.h"
#import <ECFoundation/NSURL+ECAdditions.h>

static NSString * const ACProjectsSubfolderName = @"ACLocalProjects";

/*
 ArtCode URL format:
 Specify all identifiers in the preamble so that they can be changed if needed.
 All identifiers should be as short as possible and unique within their respective group.
 The format string is <scheme>:<type identifier>?<parameter identifier>=<parameter value>[& ...]
 Examples:
 The file main.c in the root directory for the project called "Project 1"
 ac:f?p=Project%201/main.c
 The subgroup Icons in the group Images in the folder Resources in the project TestProject
 ac:g?p=TestProject/Resources&g=Images/Icons
 */

// Scheme
static NSString * const ACURLScheme = @"ac";

// Object types identifiers
static NSString * const ACURLProjectIdentifier = @"p";
static NSString * const ACURLFolderIdentifier = @"f";
static NSString * const ACURLGroupIdentifier = @"g";
static NSString * const ACURLFileIdentifier = @"c";

// Object parameters identifiers
static NSString * const ACURLObjectPathIdentifier = @"p";
static NSString * const ACURLObjectGroupIdentifier = @"g";

@implementation NSURL (ACURL)

- (BOOL)isACURL
{
    return [self.scheme isEqualToString:ACURLScheme];
}

- (NSString *)ACObjectName
{
    NSDictionary *parameters = [self queryDictionary];
    switch ([self ACObjectType])
    {
        case ACObjectTypeProject:
        case ACObjectTypeFolder:
        case ACObjectTypeFile:
            return [[parameters objectForKey:ACURLObjectPathIdentifier] lastPathComponent];
        case ACObjectTypeGroup:
            return [[parameters objectForKey:ACURLObjectGroupIdentifier] lastPathComponent];
        case ACObjectTypeApplication:
        case ACObjectTypeUnknown:
        default:
            return nil;
    }
}

- (ACObjectType)ACObjectType
{
    NSString *identifier = [[self pathComponents] objectAtIndex:0];
    if ([identifier isEqualToString:ACURLProjectIdentifier])
        return ACObjectTypeProject;
    else if ([identifier isEqualToString:ACURLFolderIdentifier])
        return ACObjectTypeFolder;
    else if ([identifier isEqualToString:ACURLGroupIdentifier])
        return ACObjectTypeGroup;
    else if ([identifier isEqualToString:ACURLFileIdentifier])
        return ACObjectTypeFile;
    else
        return ACObjectTypeUnknown;
}

- (NSURL *)ACObjectFileURL
{
    NSDictionary *parameters = [self queryDictionary];
    switch ([self ACObjectType])
    {
        case ACObjectTypeProject:
        case ACObjectTypeFolder:
        case ACObjectTypeFile:
            return [[[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACProjectsSubfolderName] URLByAppendingPathComponent:[parameters objectForKey:ACURLObjectPathIdentifier]];
        case ACObjectTypeGroup:
        case ACObjectTypeApplication:
        case ACObjectTypeUnknown:
        default:
            return nil;
    }
}

@end
