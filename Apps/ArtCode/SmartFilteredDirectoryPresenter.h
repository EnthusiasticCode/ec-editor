//
//  SmartFilteredDirectoryPresenter.h
//  ArtCode
//
//  Created by Uri Baghin on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryPresenter.h"

/// Known issues: Replacement changes to fileURLs are done before the "will" callback is triggered.
@interface SmartFilteredDirectoryPresenter : DirectoryPresenter

@property (nonatomic, strong) NSString *filterString;

/// Returns the hitmask for a certain filtered file URL
- (NSIndexSet *)hitMaskForFileURL:(NSURL *)fileURL;

@end
