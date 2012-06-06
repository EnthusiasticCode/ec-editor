//
//  DocSetBookmarksController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DocSetBookmarksController, DocSet;

@protocol DocSetBookmarksControllerDelegate <NSObject>

/// Returns a string representing the title for the given DocSet URL that wants to be added as a bookmark.
/// If anchor title is non-nil, it should be set to the title for the anchor part of the URL.
- (NSString *)docSetBookmarksController:(DocSetBookmarksController *)controller titleForBookmarksAtURL:(NSURL *)url anchorTitle:(NSString **)anchorTitle;

@end

/// Maganes the bookmarks of the given docset. Bookmarks are saved inside the .docset bundle itself as a bookmarks.plist file.
@interface DocSetBookmarksController : UITableViewController

@property (nonatomic, weak) id<DocSetBookmarksControllerDelegate> delegate;

/// The DocSet of which manage bookmarks.
/// This property will be automatically changed to the currentDocSet if the ArtCodeTab is present.
@property (nonatomic, strong) DocSet *docSet;

@end
