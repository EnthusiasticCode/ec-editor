//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileSystemFile.h"

@class RACPropertySubject;

@interface FileSystemFile (TextFile)

- (RACPropertySubject *)explicitSyntaxIdentifierSubject;

- (RACPropertySubject *)explicitEncodingSubject;

- (RACPropertySubject *)bookmarksSubject;

@end
