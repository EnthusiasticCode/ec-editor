//
//  RCIODirectory+ArtCode.h
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

const struct {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *url;
} ArtCodeRemoteAttributeKeys = {
	.name = @"name",
	.url = @"url",
};

@interface RCIODirectory (ArtCodeExtendedAttributes)

- (RACPropertySubject *)labelColorSubject;

- (RACPropertySubject *)newlyCreatedSubject;

- (RACPropertySubject *)remotesSubject;

@end
