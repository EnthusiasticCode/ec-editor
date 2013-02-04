//
//  RCIODirectory+ArtCode.h
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@interface RCIODirectory (ArtCodeExtendedAttributes)

- (RACPropertySubject *)labelColorSubject;

- (RACPropertySubject *)newlyCreatedSubject;

@end
