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
/// lineRange in input is the desired range of lines, in ouput its length
/// should be less or equal to the input value to indicate how many lines 
/// have actually been return.
/// endOfString is an output parameter that should be set to YES if the 
/// requested line range contains the end of the source string.
/// The returned string should contain an additional new line at the end of
/// the source text for optimal rendering.
- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString;

@optional
/// When implemented, this delegate method should return the total number 
/// of lines in the input text. Lines that exceed the given maximum length
/// of characters shold be considered as multiple lines. If this method
/// returns 0 a different estime will be used.
- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength;

@end
