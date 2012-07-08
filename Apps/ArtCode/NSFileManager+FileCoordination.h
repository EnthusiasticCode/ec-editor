//
//  NSFileManager+FileCoordination.h
//  ArtCode
//
//  Created by Uri Baghin on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (FileCoordination)

+ (void)coordinatedDeleteItemsAtURLs:(NSArray *)urls completionHandler:(void(^)(NSError *error))completionHandler;

@end
