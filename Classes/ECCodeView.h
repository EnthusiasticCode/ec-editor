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


@interface ECCodeView : OUIEditableFrame
{

}
@property (nonatomic,retain) NSArray *autoCompletionTokens;
@property (nonatomic,retain) UITextChecker *textChecker;

- (NSRange)completionRange;


@end
