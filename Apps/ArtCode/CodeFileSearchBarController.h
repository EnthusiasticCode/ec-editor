//
//  CodeFileSearchBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CodeFileController;

/// Options used to choose how to match the search phrase
enum {
  CodeFileSearchHitMustContain,
  CodeFileSearchHitMustStartWith,
  CodeFileSearchHitMustMatch,
  CodeFileSearchHitMustEndWith
};
typedef NSUInteger CodeFileSearchHitMustOption;


@interface CodeFileSearchBarController : UIViewController <UITextFieldDelegate>

#pragma mark Controller Setup

@property (weak, nonatomic) CodeFileController *targetCodeFileController;

@property (weak, nonatomic) IBOutlet UITextField *findTextField;
@property (weak, nonatomic) IBOutlet UITextField *replaceTextField;
@property (weak, nonatomic) IBOutlet UILabel *findResultLabel;
@property (weak, nonatomic) IBOutlet UIButton *previousResultButton;
@property (weak, nonatomic) IBOutlet UIButton *nextResultButton;

- (IBAction)moveResultAction:(id)sender;
- (IBAction)toggleReplaceAction:(id)sender;
- (IBAction)closeBarAction:(id)sender;

- (IBAction)replaceSingleAction:(id)sender;
- (IBAction)replaceAllAction:(id)sender;

#pragma mark Filtering Options

@property (nonatomic) NSRegularExpressionOptions regExpOptions;
@property (nonatomic) CodeFileSearchHitMustOption hitMustOption;

@property (nonatomic, readonly, copy) NSArray *searchFilterMatches;

@end

// View used as the container for the search bar.
@interface CodeFileSearchBarView : UIView
@end

// Text field with increased left margin.
@interface CodeFileSearchTextField : UITextField
@end