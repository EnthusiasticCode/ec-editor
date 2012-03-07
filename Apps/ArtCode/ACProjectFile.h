//
//  ACProjectFile.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem.h"
@class FileBuffer;

@interface ACProjectFile : ACProjectFileSystemItem

@property (nonatomic) int fileEncoding; // Default NSUTF8FileEncoding
@property (nonatomic, strong) NSString *codeFileExplicitSyntaxIdentifier; // file syntax to be used for syntax highlight. If nill the system should use the most appropriate file type based on the file path
- (NSString *)codeFileSyntaxIdentifier; // Returns the explicit file syntax identifier or one derived from the file path or content
@property (nonatomic, strong, readonly) FileBuffer *codeFileBuffer;

@end
