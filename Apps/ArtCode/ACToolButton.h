//
//  ACToolButton.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACToolButton : UIButton

/// Identifier for the tool that this button will segue to.
/// HAX this property is read from the disabled button title
@property (nonatomic, readonly, strong) NSString *toolIdentifier;

@end
