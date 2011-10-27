//
//  TMBundle.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMBundle : NSObject <NSDiscardableContent>

@property (nonatomic, strong, readonly) NSURL *bundleURL;
@property (nonatomic, strong, readonly) NSString *bundleName;
@property (nonatomic, strong, readonly) NSArray *syntaxes;

- (id)initWithBundleURL:(NSURL *)bundleURL;

@end
