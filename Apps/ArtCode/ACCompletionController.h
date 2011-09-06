//
//  ACCompletionController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCodeUnit;
@class ECCodeCompletionResult;


@interface ACCompletionController : UITableViewController

/// Initialize a new completion controller that will use the given code unit to
/// generate completions.
- (id)initWithCodeUnit:(ECCodeUnit *)codeUnit;

/// Filter completions usign the given filter located at the provided range in
/// the code unit source file connected with the receiver.
- (void)applyPrefixFilterString:(NSString *)prefixFilter atTextRange:(NSRange)prefixFilterRange;

/// A block of code called when a completion is selected to be inserted.
@property (nonatomic, copy) void(^resultSelectedBlock)(ECCodeCompletionResult *result);

@end
