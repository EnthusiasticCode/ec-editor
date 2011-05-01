//
//  ECCodeView.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeViewDataSource.h"


typedef enum {
    ECCodeViewNavigatorDisplayNone,
    ECCodeViewNavigatorDisplayAuto,
    ECCodeViewNavigatorDisplayAlways
} ECCodeViewNavigatorDisplayMode;

@interface ECCodeView : UIScrollView <UIKeyInput, UITextInputTraits, UITextInput>

/// The datasource for the text displayed by the code view. Default is self.
/// If this datasource is not self, the text property will have no effect.
@property (nonatomic, assign) id<ECCodeViewDataSource> datasource;

#pragma mark Managing Text Content

/// Set the text fot the control. This property is only used if textDatasource
/// is the code view itself.
@property (nonatomic, retain) NSString *text;

/// Insets of the text.
@property (nonatomic) UIEdgeInsets textInsets;

/// Invalidate the text making the receiver redraw it.
- (void)updateAllText;

/// Invalidate a particular section of the text making the reveiver redraw it.
- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange;

#pragma mark Generating and Retrieving Thumbnails

/// Indicates how to show thumbnails inside the receiver. If produceThumbnails in NO
/// this property has no effects.
@property (nonatomic) ECCodeViewNavigatorDisplayMode navigatorDisplayMode;

@property (nonatomic) CGFloat navigatorWidth;

@property (nonatomic, retain) UIColor *navigatorBackgroundColor;

/// This method will generate (if needed) thumbnails for the entire source text
/// to fit the given size and execute the given block once the generation is complete. 
/// Use 0 as size's height to limit only the width of thumbnails.
/// The given block can be executed in the main thread if so specified, otherwise
/// it will be executed on a serial background queue.
/// The function return immediatly if synchronous is NO, otherwise it will block
/// the execution untill the thumbnails are created and the given block is finished.
- (void)thumbnailsFittingTotalSize:(CGSize)size 
               enumerateUsingBlock:(void(^)(UIImage *thumbnail, NSUInteger index, CGFloat yOffset, BOOL *stop))block 
                   completionBlock:(void(^)(void))completionBlock
                     synchronously:(BOOL)synchronous;

#pragma mark UITextInput Properties

/// An input delegate that is notified when text changes or when the selection changes.
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;

/// An input tokenizer that provides information about the granularity of text units.
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;

/// A dictionary of attributes that describes how marked text should be drawn.
@property (nonatomic, copy) NSDictionary *markedTextStyle;

@end
