//
//  ECCodeViewTokenizer.h
//  CodeView
//
//  Created by Nicola Peduzzi on 07/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeView;

@interface ECCodeViewTokenizer : UITextInputStringTokenizer //NSObject <UITextInputTokenizer>

- (id)initWithCodeView:(ECCodeView *)codeView;

@end
