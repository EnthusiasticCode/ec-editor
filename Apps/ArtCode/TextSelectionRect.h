//
//  TextSelectionRect.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/10/12.
//
//

#import <UIKit/UIKit.h>

@interface TextSelectionRect : UITextSelectionRect

- (id)initWithRect:(CGRect)rect textRange:(UITextRange *)range isStart:(BOOL)isStart isEnd:(BOOL)isEnd;

@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, readonly) UITextRange *range;
@property (nonatomic, readonly) UITextWritingDirection writingDirection;
@property (nonatomic, readonly) BOOL containsStart; // Returns YES if the rect contains the start of the selection.
@property (nonatomic, readonly) BOOL containsEnd; // Returns YES if the rect contains the end of the selection.
@property (nonatomic, readonly) BOOL isVertical; // Returns YES if the rect is for vertically oriented text.

@end
