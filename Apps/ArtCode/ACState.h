//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACState : NSObject

+ (ACState *)sharedState;
@property (nonatomic, copy, readonly) NSOrderedSet *projects;

- (void)moveProjectAtPath:(NSString *)source toPath:(NSString *)destination;
- (UIColor *)colorForProjectAtPath:(NSString *)path;
- (void)setColor:(UIColor *)color forProjectAtPath:(NSString *)path;
- (BOOL)projectExistsAtPath:(NSString *)path;

@end

@interface ACStateProject : NSObject

@property (nonatomic, copy) NSString *fullPath;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIColor *color;

@end
