//
//  QuickFolderInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFolderInfoController.h"
#import "QuickBrowsersContainerController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

@implementation QuickFolderInfoController

+ (id)new {
  return [[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickFolderInfo"];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.folderNameLabel.text = [self.artCodeTab.currentLocation name];
  
  // Calculate file and folders count in current folder
  NSUInteger fileCount = 0;
  NSUInteger folderCount = 0;
  NSNumber *isDirectory = nil;
  for (NSURL *url in [[NSFileManager defaultManager] enumeratorAtURL:self.artCodeTab.currentLocation.url includingPropertiesForKeys:@[ NSURLIsDirectoryKey ] options:0 errorHandler:NULL]) {
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    if ([isDirectory boolValue]) {
      folderCount++;
    } else {
      fileCount++;
    }
  }
  
  // Set files and folder count labels
  self.folderFileCountLabel.text = [NSString stringWithFormat:@"%u", fileCount];
  self.folderSubfolderCountLabel.text = [NSString stringWithFormat:@"%u", folderCount];
}

- (void)viewDidUnload {
  [self setFolderSubfolderCountLabel:nil];
  [super viewDidUnload];
}
@end
