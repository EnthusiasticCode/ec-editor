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
static NSString * const remotesKey = @"com.enthusiasticcode.artcode.Remotes";

const struct ArtCodeRemoteAttributeKeys ArtCodeRemoteAttributeKeys = {
	.name = @"name",
	.url = @"url",
};

@implementation RCIODirectory (ArtCodeExtendedAttributes)

- (RACPropertySubject *)labelColorSubject {
	return [self extendedAttributeSubjectForKey:labelColorKey];
}

- (RACPropertySubject *)newlyCreatedSubject {
	return [self extendedAttributeSubjectForKey:newlyCreatedKey];
}

- (RACPropertySubject *)remotesSubject {
	return [self extendedAttributeSubjectForKey:remotesKey];
}

@end
