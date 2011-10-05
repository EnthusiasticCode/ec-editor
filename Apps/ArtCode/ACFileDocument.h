//
//  ACFileDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCodeUnit;

@interface ACFileDocument : UIDocument

- (NSString *)contentString;

- (void)loadCodeUnitWithCompletionHandler:(void (^)(ECCodeUnit *codeUnit))completionHandler;

@end