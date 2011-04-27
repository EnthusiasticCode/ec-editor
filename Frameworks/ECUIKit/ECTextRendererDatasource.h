//
//  ECTextRendererDatasource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 17/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECTextRenderer;

@protocol ECTextRendererDataSource <NSObject>
@required

/// An implementer of this method should return a string from the input
/// text that start at the given line location and that contain maximum
/// the given line count.
- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange;

@optional
/// When implemented, this delegate method should return the total number 
/// of lines in the input text. Lines that exceed the given maximum length
/// of characters shold be considered as multiple lines. If this method
/// returns 0 a different estime will be used.
- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength;

@end
