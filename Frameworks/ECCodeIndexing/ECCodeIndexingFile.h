//
//  ECCodeIndexingFile.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECCodeIndexingFile : NSObject
@property (nonatomic, readonly, retain) NSURL *URL;
@property (nonatomic, readonly, retain) NSString *extension;
@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSString *buffer;
@property (nonatomic, getter = isDirty) BOOL dirty;
- (id)initWithURL:(NSURL *)url;
+ (id)fileWithURL:(NSURL *)url;
@end
