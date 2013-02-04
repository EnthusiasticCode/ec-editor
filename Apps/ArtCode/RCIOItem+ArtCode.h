//
//  RCIOItem+ArtCode.h
//  ArtCode
//
//  Created by Uri Baghin on 04/02/2013.
//
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@interface RCIOItem (ArtCodeBookmarks)

- (RACSignal *)bookmarksSignal;

@end
