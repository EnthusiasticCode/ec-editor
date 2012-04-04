//
//  Operation.h
//  ArtCode
//
//  Created by Uri Baghin on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Operation : NSOperation

/// Designated initializer.
/// @param completionHandler Optional completion handler to execute when the operation is finished executing.
/// Success will be NO if the operation was cancelled.
/// The completionHandler is executed on the same queue the operation was created in.
- (id)initWithCompletionHandler:(void(^)(BOOL success))completionHandler;

@end
