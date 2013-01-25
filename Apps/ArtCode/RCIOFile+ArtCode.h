//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@interface RCIOFile (ArtCode)

- (RACPropertySubject *)explicitSyntaxIdentifierSubject;

- (RACPropertySubject *)explicitEncodingSubject;

- (RACPropertySubject *)bookmarksSubject;

@end
