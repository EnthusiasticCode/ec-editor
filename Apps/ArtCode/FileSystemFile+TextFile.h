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

- (RACPropertySubject *)explicitSyntaxIdentifier;

- (RACPropertySubject *)explicitEncoding;

- (RACPropertySubject *)bookmarks;

@end
