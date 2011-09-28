//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    ACObjectTypeApplication,
    ACObjectTypeProject,
    ACObjectTypeFolder,
    ACObjectTypeGroup,
    ACObjectTypeFile,
} ACObjectType;

@interface NSURL (ACURL)

/// Returns whether or not the URL refers to an AC object
- (BOOL)isACURL;

/// Returns the name of the object referenced by the ACURL
- (NSString *)ACObjectName;

/// Returns the type of the object referenced by the ACURL
- (ACObjectType)ACObjectType;

@end
