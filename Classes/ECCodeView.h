//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ECAttributedTextView.h"
#import "ECPopoverTableController.h"
#import "ECCodeViewCompletionProvider.h"
#import "ECCodeViewSyntaxChecker.h"

/*! A subclass of UITextView with additional features for display and editing code. */
@interface ECCodeView : ECAttributedTextView
{

}
/* An array of all currently loaded completion providers. */
@property (nonatomic, readonly, copy) NSArray *completionProviders;
/* An array of all currently loaded syntax checkers. */
@property (nonatomic, readonly, copy) NSArray *syntaxCheckers;
// popovertable used to display completions
@property (nonatomic, retain) ECPopoverTableController *completionPopover;

/* Add a new completion provider. It is not checked for duplicity. */
- (void)addCompletionProvider:(id<ECCodeViewCompletionProvider>)completionProvider;
/* Add a new syntax checker. It is not checked for duplicity. */
- (void)addSyntaxChecker:(id<ECCodeViewSyntaxChecker>)syntaxChecker;
// displayers the completion popovertable if possible
- (void)showCompletions;

@end
