//
//  ECTextRendererDelegate.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 17/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECTextRenderer;

@protocol ECTextRendererDelegate <NSObject>
@optional

/// Called when the renderer update a part of its content.
- (void)textRenderer:(ECTextRenderer *)sender didChangeRenderForTextWithinRect:(CGRect)originalRect toRect:(CGRect)newRect;

@end