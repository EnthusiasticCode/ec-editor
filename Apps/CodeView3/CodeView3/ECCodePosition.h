//
//  ECCodePosition.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 21/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECCodePosition : UITextPosition <NSCopying>

@property (nonatomic, readonly) NSUInteger index;

@property (nonatomic, readonly) NSUInteger row;

@property (nonatomic, readonly) NSUInteger column;

@end
