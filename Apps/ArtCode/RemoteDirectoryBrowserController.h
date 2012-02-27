//
//  UploadBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteBrowserController.h"

@interface RemoteDirectoryBrowserController : RemoteBrowserController

/// The URL that the user selected.
@property (nonatomic, strong, readonly) NSURL *selectedURL;

@end
