//
//  ECCodeViewCompletion.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UITextInput.h>

/*! A protocol describing the methods needed to provide an ECCodeView with completions. */
@protocol ECCodeViewCompletionProvider <NSObject>

/*! A method called by the ECCodeView to retrieve completions.
 *
 *\param selection The current text selection.
 *\param string The text the ECCodeView is currently displaying.
 */
- (NSArray *)completionsWithSelection:(NSRange)selection inString:(NSString *)string;

@end
