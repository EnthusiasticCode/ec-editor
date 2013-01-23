//
//  NSURL+ArtCode.m
//  ArtCode
//
//  Created by Uri Baghin on 22/01/2013.
//
//

#import "NSURL+ArtCode.h"

#import "NSURL+Utilities.h"

static NSString * const localProjectsFolderName = @"LocalProjects";

@implementation NSURL (ArtCode)

+ (NSURL *)projectsListDirectory {
	return [NSURL.applicationLibraryDirectory URLByAppendingPathComponent:localProjectsFolderName];
}

- (NSURL *)projectRootDirectory {
	if (![self.absoluteString hasPrefix:NSURL.projectsListDirectory.absoluteString]) return nil;
	NSArray *selfComponents = self.pathComponents;
	NSArray *projectsListDirectoryComponents = NSURL.projectsListDirectory.pathComponents;
	if (projectsListDirectoryComponents <= selfComponents) return nil;
	return [NSURL.projectsListDirectory URLByAppendingPathComponent:selfComponents[projectsListDirectoryComponents.count]];
}

@end
