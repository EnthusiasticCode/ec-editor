//
//  QuickFileInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileInfoController.h"
#import "QuickBrowsersContainerController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

#import "CodeFileController.h"
#import "TMUnit.h"
#import "TMSyntaxNode.h"

#import "QuickFileHighlightTableController.h"

@implementation QuickFileInfoController

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
  if (!self) return nil;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Reveal") style:UIBarButtonItemStylePlain target:self action:@selector(_revealAction:)];
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.fileNameLabel.text = [self.artCodeTab.currentLocation name];
  self.fileSizeLabel.text = [NSString stringWithFormat:@"%.2f KB", (double)[[NSFileManager.defaultManager attributesOfItemAtPath:self.artCodeTab.currentLocation.url.path error:NULL][NSFileSize] unsignedIntValue] / 1024.0];
  ASSERT([self.quickBrowsersContainerController.contentController isKindOfClass:CodeFileController.class]);
  self.fileHighlightTypeLabel.text = [(CodeFileController *)self.quickBrowsersContainerController.contentController codeUnit].syntax.name;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:QuickFileHighlightTableController.class]) {
    ASSERT([self.quickBrowsersContainerController.contentController isKindOfClass:CodeFileController.class]);
    [(QuickFileHighlightTableController *)segue.destinationViewController setCodeFileController:(CodeFileController *)self.quickBrowsersContainerController.contentController];
  }
}

#pragma mark - Private Methods

- (void)_revealAction:(id)sender {
	[self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
	
	NSURL *url = self.artCodeTab.currentLocation.url;
	[self.artCodeTab pushFileURL:url.URLByDeletingLastPathComponent dataDictionary:@{@"reveal" : url.lastPathComponent}];
}

@end
