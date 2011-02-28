//
//  ECCodeIndexingFile.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECCodeIndexingFile : NSObject
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSString *buffer;
- (id)initWithURL:(NSURL *)url language:(NSString *)language buffer:(NSString *)buffer;
+ (id)fileWithURL:(NSURL *)url language:(NSString *)language buffer:(NSString *)buffer;
@end
