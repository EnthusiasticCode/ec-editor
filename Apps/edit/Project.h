//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Project : NSObject
@property (nonatomic, strong, readonly) NSString *bundlePath;
@property (nonatomic, strong, readonly) NSString *name;
- (id)initWithBundle:(NSString *)bundlePath;
- (void)saveContext;
- (NSOrderedSet *)children;
@end
