//
//  ECCarpetPanelView.h
//  edit
//
//  Created by Nicola Peduzzi on 17/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// View to be instantiated by ECCarpetView only
@interface ECCarpetPanelView : UIView {
    
}

@property CGFloat panelSize;
@property NSInteger panelPosition;

// Return the panel size in units. If panelSize is greater than 1 it is 
// returnerd directrly. Otherwhise a conversion from percent of superview size
// is provided.
- (CGFloat)panelSizeInUnits;

@end
