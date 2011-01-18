//
//  ECCarpetView.h
//  edit
//
//  Created by Nicola Peduzzi on 17/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern NSString* const ECCarpetPanelMain;
extern NSString* const ECCarpetPanelOne;
extern NSString* const ECCarpetPanelTwo;

typedef enum {
    ECCarpetHorizontal = 0,
    ECCarpetVertical
} ECCarpetViewDirection;

@interface ECCarpetView : UIView {
@private
    UIView * panelMain;
    NSMutableDictionary * panelsDictionary;
    NSArray * sortedPanels;
}

// A delegate for this view may respond to the following messages:
// - (BOOL)carpetView:(ECCarpetView*)_ willShowPanelNamed:(NSString*)
// - (void)carpetView:(ECCarpetView*)_ didShowPanelNamed:(NSString*)
@property (assign) id delegate;
@property ECCarpetViewDirection direction;

- (id)initWithFrame:(CGRect)frame panelNames:(NSArray *)panels direction:(ECCarpetViewDirection)direction;

// Get the panel with the given name or null if no pannel with that name
// has been found. ECCarpetPanelMain is guarantee to be present.
- (UIView*)panelWithName:(NSString *)name;

// Add a new panel to the carpet view. If a panel with the given name
// already exists, it will be returned instead.
- (UIView*)addPanelWithName:(NSString *)name size:(CGFloat)size position:(NSInteger)position;

// Get the size of the specified panel. If size is <= 1 it is considered a 
// percentual size, otherwise a point size.
- (CGFloat)panelSizeForPanelNamed:(NSString *)name;

// Set the size of the specified panel. If size is <= 1 it is considered a 
// percentual size, otherwise a point size.
- (void)setPanelSize:(CGFloat)size forPanelNamed:(NSString *)name;

// Convinience message to add a subview to a panel.
- (void)addSubview:(UIView *)view toPanelNamed:(NSString *)name;

@end
