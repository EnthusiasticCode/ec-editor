//
//  ECRelationalTableViewItem.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ECRelationalTableViewItemStyleDefault,	// Simple cell with text label and optional image view (behavior of ECRelationalTableViewItem in iPhoneOS 2.x)
    ECRelationalTableViewItemStyleValue1,		// Left aligned label on left and right aligned label on right with blue text (Used in Settings)
    ECRelationalTableViewItemStyleValue2,		// Right aligned label on left with blue text and left aligned label on right (Used in Phone/Contacts)
    ECRelationalTableViewItemStyleSubtitle	// Left aligned label on top and left aligned label on bottom with gray text (Used in iPod).
} ECRelationalTableViewItemStyle;             // available in iPhone OS 3.0

typedef enum {
    ECRelationalTableViewItemSeparatorStyleNone,
    ECRelationalTableViewItemSeparatorStyleSingleLine,
    ECRelationalTableViewItemSeparatorStyleSingleLineEtched   // This separator style is only supported for grouped style table views currently
} ECRelationalTableViewItemSeparatorStyle;

typedef enum {
    ECRelationalTableViewItemSelectionStyleNone,
    ECRelationalTableViewItemSelectionStyleBlue,
    ECRelationalTableViewItemSelectionStyleGray
} ECRelationalTableViewItemSelectionStyle;

typedef enum {
    ECRelationalTableViewItemEditingStyleNone,
    ECRelationalTableViewItemEditingStyleDelete,
    ECRelationalTableViewItemEditingStyleInsert
} ECRelationalTableViewItemEditingStyle;

typedef enum {
    ECRelationalTableViewItemAccessoryNone,                   // don't show any accessory view
    ECRelationalTableViewItemAccessoryDisclosureIndicator,    // regular chevron. doesn't track
    ECRelationalTableViewItemAccessoryDetailDisclosureButton, // blue button w/ chevron. tracks
    ECRelationalTableViewItemAccessoryCheckmark               // checkmark. doesn't track
} ECRelationalTableViewItemAccessoryType;

enum {
    ECRelationalTableViewItemStateDefaultMask                     = 0,
    ECRelationalTableViewItemStateShowingEditControlMask          = 1 << 0,
    ECRelationalTableViewItemStateShowingDeleteConfirmationMask   = 1 << 1
};
typedef NSUInteger ECRelationalTableViewItemStateMask;        // available in iPhone OS 3.0

@interface ECRelationalTableViewItem : NSObject {
    
}

@end
