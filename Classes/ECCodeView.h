//
//  ECCodeView.h
//  edit
//
//  Created by Nicola Peduzzi on 15/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UITextChecker.h>
#import <UIKit/UIPopoverController.h>
#import "OUIEditableFrame.h"
#import "CompletionListController.h"


@interface ECCodeView : OUIEditableFrame <CompletionListControllerDelegate>
{
    UITextChecker *_textChecker;
    UIPopoverController *_completionListPopover;
    CompletionListController *_completionList;
}
@property (nonatomic,retain) NSArray *autoCompletionTokens;
@property (nonatomic,readonly) UITextChecker *textChecker;
@property (nonatomic,readonly) UIPopoverController *completionListPopover;
@property (nonatomic,readonly) CompletionListController *completionList;


- (NSRange)completionRange;
- (void)showCompletions;

@end
