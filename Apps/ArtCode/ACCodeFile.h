//
//  ACCodeFile.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ECUIKit/ECCodeView.h>
#import <ECFoundation/ECFileBuffer.h>
@class TMTheme;

@interface ACCodeFile : NSObject <ECCodeViewDataSource, ECFileBufferConsumer>

@property (nonatomic, strong, readonly) ECFileBuffer *fileBuffer;
@property (nonatomic, strong) TMTheme *theme;
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

- (id)initWithFileURL:(NSURL *)fileURL;

@end
