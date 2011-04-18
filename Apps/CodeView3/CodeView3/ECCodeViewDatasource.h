//
//  ECCodeViewDatasource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 18/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECTextRendererDatasource.h"


@class ECCodeView4;

@protocol ECCodeViewDatasource <ECTextRendererDatasource>
@optional

/// When implemented return a dictionary with \c ECOverlayStyle as key to 
/// \c NSIndexSet as values representing the ranges of string to apply the style to.
- (NSDictionary *)codeView:(ECCodeView4 *)sender overlaysForTextRange:(NSRange)range;

@end
