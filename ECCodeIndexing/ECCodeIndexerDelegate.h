//
//  ECCodeIndexerDelegate.h
//  edit
//
//  Created by Uri Baghin on 2/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ECCodeIndexerDelegate <NSObject>

- (NSString *)indexedTextBuffer;
- (NSRange)indexedTextSelection;

@end
