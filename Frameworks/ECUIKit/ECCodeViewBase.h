//
//  ECCodeViewBase.h
//  CodeView
//
//  Created by Nicola Peduzzi on 01/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextRenderer.h"
#import "ECCodeViewDataSource.h"

@interface ECCodeViewBase : UIScrollView <ECTextRendererDelegate> {
@protected
    id<ECCodeViewDataSource> datasource;
    ECTextRenderer *renderer;
    NSOperationQueue *renderingQueue;
    UIEdgeInsets textInsets;
    BOOL dataSourceHasCodeCanEditTextInRange;
}

#pragma mark Advanced Initialization and Configuration

/// Initialize a codeview with external renderer and rendering queue.
/// The codeview initialized with this method will be set to not own the 
/// renderer and will use it only as a consumer.
- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue;

/// Renderer used in the codeview.
@property (nonatomic, readonly) ECTextRenderer *renderer;

/// Queue where renderer should be used.
@property (nonatomic, retain) NSOperationQueue *renderingQueue;

#pragma mark Providing Source Data

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

@end
