//
//  ACProjectDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectDocument.h"
#import "ACProject.h"
#import "ACURL.h"

@implementation ACProjectDocument

+ (NSString *)persistentStoreName
{
    return @"acproject.db";
}

- (NSDictionary *)persistentStoreOptions
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
}

- (NSManagedObjectModel *)managedObjectModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Project" withExtension:@"momd"];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    // TODO: handle errors gracefully
    // for now, just debug them manually by checking [error localizedDescription]
    // NOTE: do not delete this even if it stays empty, because UIDocument fails VERY silently otherwise
    NSLog(@"Error in ACProjectDocument");
    NSLog(@"%@", self.fileURL);
    NSLog(@"%@", [error localizedDescription]);
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(detailedErrors != nil && [detailedErrors count] > 0)
        for(NSError* detailedError in detailedErrors)
            NSLog(@"  DetailedError: %@", [detailedError userInfo]);
    else
        NSLog(@"  %@", [error userInfo]);
    ECASSERT(NO);
}

@end
