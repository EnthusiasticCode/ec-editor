//
//  ACURLTarget.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACURLTarget <NSObject>
@required
- (void)openURL:(NSURL *)url;
@end
