//
//  ECMutableFileRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ECMutableTextFileRenderer : NSObject <NSStreamDelegate>

#pragma mark Creation of Text Renderers

/// Create a new instance of text file rendered with a width and height for frames.
+ (ECMutableTextFileRenderer *)textFileRendererWithFramesWidth:(CGFloat)width preferredHeight:(CGFloat)preferredHeight;

#pragma mark Manage Text Content

@property (nonatomic, retain) NSInputStream *inputStream;

@property (nonatomic, assign) NSAttributedString *string;

#pragma mark Modifying Rendering Behaviours

/// Define the maximum length for a framesetter's string. If the loaded text is 
/// longer than this parameter, multiple framesetters will be created.
/// Default to 0, will not attempt to cut the loaded text and generate only one 
/// framesetter.
@property NSUInteger framesetterStringLengthLimit;

/// The preferred height for a redering frame. This value will be used to split
/// redered text. Frame height might increase during editing of the text, if
/// A frame reaches the double of this property, it will be divided into two;
/// if it reaches the half of this property, it will be merged with another
/// frame. Set this value to CGFLOAT_MAX to have only one frame.
/// Default value is 1024. Non integer numbers will be truncated.
@property CGFloat framePreferredHeight;

/// The required rendering frame width. The width will not be automatically
/// adjusted. Set this parameter to make the rendered text wrap.
/// Default is 768. This parameter can be set to CGFLOAT_MAX to not limit width.
@property CGFloat frameWidth;

#pragma mark Rendering Content

/// Renders the content text contained in the given bounds to the specified context.
/// The given context will not be modified prior rendering. Lines will be drawn
/// with the current context transformation and it will be left at the beginning
/// of the next non redered line.
- (void)drawTextInBounds:(CGRect)bounds inContext:(CGContextRef)context;

@end
