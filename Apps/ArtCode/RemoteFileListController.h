//
//  RemoteFileListController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import <UIKit/UIKit.h>
#import "SearchableTableBrowserController.h"

@class ArtCodeRemote;
@protocol CKConnection;

@interface RemoteFileListController : SearchableTableBrowserController

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote connection:(id<CKConnection>)connection path:(NSString *)remotePath;

@end
