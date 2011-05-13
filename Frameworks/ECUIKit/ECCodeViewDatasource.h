//
//  ECCodeViewDatasource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 18/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECTextRendererDataSource.h"


@class ECCodeViewBase;

@protocol ECCodeViewDataSource <ECTextRendererDataSource>
@required

/// When implemented return the length of the text in the datasource.
- (NSUInteger)textLength;

/// Return the substring in the given range. Used to implement
/// \c UITextInput methods.
- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range;

@optional

/// Returns a value that indicate if the codeview can edit the datasource
/// in the specified text range.
- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range;

/// Commit a change for the given range with the given string.
/// The datasource is responsible for calling one of the update methods of the 
/// codeview after the text has been changed.
- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range;

@end
