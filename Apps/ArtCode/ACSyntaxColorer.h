//
//  ACSyntaxColorer.h
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECFileBuffer, TMTheme, ECCodeUnit;

@interface ACSyntaxColorer : NSObject

@property (nonatomic, strong) TMTheme *theme;
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

- (id)initWithFileBuffer:(ECFileBuffer *)fileBuffer;
- (ECFileBuffer *)fileBuffer;
- (ECCodeUnit *)codeUnit;
- (void)applySyntaxColoring;

@end
