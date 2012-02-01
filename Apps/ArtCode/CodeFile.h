//
//  CodeFile.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodeView.h"
#import "FileBuffer.h"
@class TMTheme;

@interface CodeFile : NSObject <CodeViewDataSource, FileBufferConsumer>

@property (nonatomic, strong, readonly) FileBuffer *fileBuffer;
@property (nonatomic, strong) TMTheme *theme;

- (id)initWithFileURL:(NSURL *)fileURL;

+ (void)saveFilesToDisk;

@end
