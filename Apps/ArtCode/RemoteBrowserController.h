//
//  RemoteBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchableTableBrowserController.h"

@interface RemoteBrowserController : SearchableTableBrowserController

/// Set the URL to open. This methos will activelly connect to the URL.
@property (nonatomic, strong) NSURL *URL;

@end
