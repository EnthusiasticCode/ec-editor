//
//  ACCodeViewCompletionsController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 15/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCodeIndex, ECCodeUnit;
@class ACCodeFileKeyboardAccessoryView;
@class ACCodeFileController, ACCodeFileCompletionCell;

@interface ACCodeFileCompletionsController : UITableViewController

#pragma mark Targets

@property (weak, nonatomic) ACCodeFileController *targetCodeFileController;
@property (weak, nonatomic) ACCodeFileKeyboardAccessoryView *targetKeyboardAccessoryView;

#pragma mark Completions

/// The offset in the target code file controller's document content for which show completions. Setting this property will make the controller reload the completions.
@property (nonatomic) NSUInteger offsetInDocumentForCompletions;

/// Return a value indicating if the controller has completions with the current offset in document.
- (BOOL)hasCompletions;

/// Cell instantiated by loading the CompletionControllerCell xib.
@property (strong, nonatomic) IBOutlet ACCodeFileCompletionCell *completionCell;

@end
