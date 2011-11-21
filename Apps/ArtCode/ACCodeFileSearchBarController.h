//
//  ACCodeFileSearchBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileController;

/// Options used to choose how to match the search phrase
enum {
    ACCodeFileSearchHitMustContain,
    ACCodeFileSearchHitMustStartWith,
    ACCodeFileSearchHitMustMatch,
    ACCodeFileSearchHitMustEndWith
};
typedef NSUInteger ACCodeFileSearchHitMustOption;


@interface ACCodeFileSearchBarController : UIViewController <UITextFieldDelegate>

#pragma mark Controller Setup

@property (weak, nonatomic) ACCodeFileController *targetCodeFileController;

@property (strong, nonatomic) IBOutlet UITextField *findTextField;
@property (strong, nonatomic) IBOutlet UITextField *replaceTextField;
@property (strong, nonatomic) IBOutlet UILabel *findResultLabel;

- (IBAction)moveResultAction:(id)sender;
- (IBAction)toggleReplaceAction:(id)sender;
- (IBAction)closeBarAction:(id)sender;

- (IBAction)replaceSingleAction:(id)sender;
- (IBAction)replaceAllAction:(id)sender;

#pragma mark Filtering Options

@property (nonatomic) NSRegularExpressionOptions regExpOptions;
@property (nonatomic) ACCodeFileSearchHitMustOption hitMustOption;

@property (readonly, copy) NSArray *searchFilterMatches;

@end

// View used as the container for the search bar.
@interface ACCodeFileSearchBarView : UIView
@end

// Text field with increased left margin.
@interface ACCodeFileSearchTextField : UITextField
@end