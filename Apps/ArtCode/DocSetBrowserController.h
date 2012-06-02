//
//  DocSetBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocSetBrowserController : UIViewController

/// The currently displayed docset URL.
/// This URL has to be in the form: docset://<docset name>[/<relative file>[#anchor]]
@property (nonatomic, strong) NSURL *docSetURL;

@end
