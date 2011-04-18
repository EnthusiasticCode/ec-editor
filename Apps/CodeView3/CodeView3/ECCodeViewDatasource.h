//
//  ECCodeViewDatasource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 18/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECTextRendererDataSource.h"


@class ECCodeView4;

@protocol ECCodeViewDataSource <ECTextRendererDataSource>
@required

/// When implemented, indicate if the given \c CodeView can send editing messages
/// to the implementer.
- (BOOL)canBeEditedByCodeView:(ECCodeView4 *)sender;

@optional

#pragma mark Returning Overlay Content

/// When implemented return a dictionary with \c ECOverlayStyle as key to 
/// \c NSIndexSet as values representing the ranges of string to apply the style to.
- (NSDictionary *)codeView:(ECCodeView4 *)sender overlaysForTextRange:(NSRange)range;

@end
