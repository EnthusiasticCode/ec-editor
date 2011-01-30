//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ECPopoverTableController.h"
#import "ECCodeIndexer.h"

/*! A subclass of UITextView with additional features for display and editing code. */
@interface ECCodeView : UITextView
{

}
/* An array of all currently loaded completion providers. */
@property (nonatomic, readonly, copy) NSArray *codeIndexers;
// popovertable used to display completions
@property (nonatomic, retain) ECPopoverTableController *completionPopover;

/* Add a new code indexer. It is not checked for duplicity. */
- (void)addCodeIndexer:(id<ECCodeIndexer>)codeIndexer;
// display the completion popovertable if possible
- (void)showCompletions;

@end
