//
//  RCIODirectory+ArtCode.m
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import "RCIODirectory+ArtCode.h"

#import "RCIOFile+ArtCode.h"

static NSString * const labelColorKey = @"com.enthusiasticcode.artcode.LabelColor";
static NSString * const newlyCreatedKey = @"com.enthusiasticcode.artcode.NewlyCreated";

@implementation RCIODirectory (ArtCodeExtendedAttributes)

- (RACPropertySubject *)labelColorSubject {
	return [self extendedAttributeSubjectForKey:labelColorKey];
}

- (RACPropertySubject *)newlyCreatedSubject {
	return [self extendedAttributeSubjectForKey:newlyCreatedKey];
}

@end
