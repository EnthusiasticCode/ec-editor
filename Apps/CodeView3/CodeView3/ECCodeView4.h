//
//  ECCodeView4.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTextRendererDatasource.h"


@interface ECCodeView4 : UIScrollView <ECTextRendererDatasource>

#pragma mark Managing Text Content

/// The datasource for the text displayed by the code view. Default is self.
/// If this datasource is not self, the text property will have no effect.
@property (nonatomic, assign) id<ECTextRendererDatasource> textDatasource;

/// Set the text fot the control. This property is only used if textDatasource
/// is the code view itself.
@property (nonatomic, retain) NSAttributedString *text;

/// Insets of the text.
@property (nonatomic) UIEdgeInsets textInsets;

@end
