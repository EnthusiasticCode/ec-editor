//
//  NSString+AppStyle.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AppStyle)

/// Returns a string that has a pretty path format that removes '.weakpkg' extensions and adds ▸ instead of /
- (NSString *)prettyPath;

@end
