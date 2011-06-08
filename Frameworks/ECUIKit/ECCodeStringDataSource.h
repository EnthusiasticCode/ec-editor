//
//  ECCodeStringDataSource.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 23/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeView.h"
#import "ECTextStyle.h"

@interface ECCodeStringDataSource : NSObject <ECCodeViewDataSource>

/// The string to be managed by the datasource
@property (nonatomic, strong) NSString *string;

/// Default style applied to the entire string.
@property (nonatomic, strong) ECTextStyle *defaultTextStyle;

/// Add a text style to the specified input string range. If the style specifies
/// an attribute already present for the string range, this will be substituted
/// with the provided one.
- (void)addTextStyle:(ECTextStyle *)textStyle toStringRange:(NSRange)range;

/// Remove all styles types specified in the given text style from the range of text.
- (void)removeTextStyle:(ECTextStyle *)textStyle fromStringRange:(NSRange)range;

/// Remove all text styles from the given range replacing them with the default style.
- (void)removeAllTextStylesFromRange:(NSRange)range;

/// Remove all text styles replacing them with the default style.
- (void)removeAllTextStyles;

@end
