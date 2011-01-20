//
//  ECCodeViewController.m
//  edit
//
//  Created by Uri Baghin on 1/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewController.h"

#import "ECCodeView.h"
#import "ECClangCodeIndexer.h"
#import "OUEFTextRange.h"


@implementation ECCodeViewController


#pragma mark -
#pragma mark Initializations and clean up

- (void)viewDidLoad
{
    // viewDidLoad can be called multiple times without deallocating the view
    if (![((ECCodeView *)self.view).completionProviders count])
    {
        ECClangCodeIndexer *codeIndexer = [[ECClangCodeIndexer alloc] init];
        [(ECCodeView *)self.view addCompletionProvider:codeIndexer];
        [codeIndexer release];
    }
}

- (void)dealloc
{
    self.view = nil;
    [super dealloc];
}

@end
