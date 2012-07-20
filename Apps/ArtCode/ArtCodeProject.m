//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProject.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"
#import "NSString+Utilities.h"

#import "ArtCodeLocation.h"


@implementation ArtCodeProject

#pragma mark - KVO overrides

+ (NSSet *)keyPathsForValuesAffectingFileURL {
  return [NSSet setWithObjects:@"name", @"projectSet.fileURL", nil];
}

+ (NSSet *)keyPathsForValuesAffectingLabelColor {
  return [NSSet setWithObject:@"labelColorString"];
}

#pragma mark - Public Methods

- (NSURL *)fileURL {
  return [[[self projectSet] fileURL] URLByAppendingPathComponent:[self name]];
}

- (UIColor *)labelColor {
  return [UIColor colorWithHexString:[self labelColorString]];
}

- (void)setLabelColor:(UIColor *)labelColor {
  [self setLabelColorString:[labelColor hexString]];
}

#pragma mark - Project-wide operations

#pragma mark - Private Methods

@end
