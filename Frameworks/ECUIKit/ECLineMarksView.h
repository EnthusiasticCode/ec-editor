//
//  ECLineMarks.h
//  edit
//
//  Created by Nicola Peduzzi on 01/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECLineMarksView;

@protocol ECLineMarksViewDelegate <NSObject>

- (void)lineMarksView:(ECLineMarksView *)view selectedMarkWithColor:(UIColor *)color atLine:(NSUInteger)index;

@end

typedef void (^DrawMarkBlock)(CGContextRef ctx, CGRect rct, UIColor *clr);

@interface ECLineMarksView : UIView {
@private
    DrawMarkBlock drawMarkBlock;
    CGSize markSize;
    UIEdgeInsets markInsets;
    NSUInteger lineCount;
    NSMutableDictionary *marks;
    
    UITapGestureRecognizer *tapMarkRecognizer;
}

@property (nonatomic, weak) id<ECLineMarksViewDelegate> delegate;

@property (nonatomic, copy) DrawMarkBlock drawMarkBlock;
@property (nonatomic) CGSize markSize;
@property (nonatomic) UIEdgeInsets markInsets;
@property (nonatomic) NSUInteger lineCount;
- (void)addMarksWithColor:(UIColor *)color forLines:(NSIndexSet *)lines;
- (void)removeAllMarks;
- (void)removaAllMarksWithColor:(UIColor *)color;

@end
