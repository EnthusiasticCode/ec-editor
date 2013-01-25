//
//  RCIODirectory+ArtCode.h
//  ArtCode
//
//  Created by Uri Baghin on 25/01/2013.
//
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@interface RCIODirectory (ArtCode)

- (RACPropertySubject *)labelColorSubject;

- (RACPropertySubject *)newlyCreatedSubject;

- (RACSignal *)bookmarksSignal;

@end
