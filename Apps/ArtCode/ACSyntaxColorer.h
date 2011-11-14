//
//  ACSyntaxColorer.h
//  ArtCode
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECAttributedUTF8FileBuffer, TMTheme, ECCodeUnit;

@interface ACSyntaxColorer : NSObject

@property (nonatomic, strong) TMTheme *theme;
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

- (id)initWithFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer;
- (ECAttributedUTF8FileBuffer *)fileBuffer;
- (ECCodeUnit *)codeUnit;
- (void)applySyntaxColoring;

@end
