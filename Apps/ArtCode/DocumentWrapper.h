//
//  DocumentWrapper.h
//  ArtCode
//
//  Created by Uri Baghin on 24/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// A wrapper around UIDocument as a workaround to the disposable nature of UIDocument.
/// UIDocument can normally be only opened and closed once during it's lifetime, DocumentWrapper automatically creates and destroys instances of a UIDocument subclass as needed to assist posing as a document that can be opened and closed multiple times, so that it can be cached / uniqued.

@interface DocumentWrapper : NSObject

/// Returns a wrapper that acts like the document returned from the given block.
/// The block may be called multiple times if the document needs to be recreated.
+ (id)wrapperWithBlock:(UIDocument *(^)(void))block;

@end
