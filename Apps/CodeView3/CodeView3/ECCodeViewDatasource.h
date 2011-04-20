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

/// When implemented return the length of the text in the datasource.
- (NSUInteger)textLength;

/// Return the substring in the given range.
- (NSString *)codeView:(ECCodeView4 *)codeView stringInRange:(NSRange)range;

@optional

/// Returns a value that indicate if the codeview can edit the datasource
/// in the specified text range.
- (BOOL)codeView:(ECCodeView4 *)codeView canEditTextInRange:(NSRange)range;

/// Commit a change for the given range with the given string.
/// The datasource is responsible for calling one of the update methods of the 
/// codeview after the text has been changed.
- (void)codeView:(ECCodeView4 *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range;

@optional

#pragma mark Returning Overlay Content

/// When implemented return a dictionary with \c ECOverlayStyle as key to 
/// \c NSIndexSet as values representing the ranges of string to apply the style to.
- (NSDictionary *)codeView:(ECCodeView4 *)sender overlaysForTextRange:(NSRange)range;

@end
