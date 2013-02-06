//
//  RCIODirectory+ArtCode.h
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

const struct ArtCodeRemoteAttributeKeys {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *url;
} ArtCodeRemoteAttributeKeys;

@interface RCIODirectory (ArtCodeExtendedAttributes)

- (RACPropertySubject *)labelColorSubject;

- (RACPropertySubject *)newlyCreatedSubject;

- (RACPropertySubject *)remotesSubject;

@end
