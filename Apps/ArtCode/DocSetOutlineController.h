//
//  DocSetOutlineController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Shows the outline loaded from a book.json DocSet file derived from the current
/// artCodeTab.currentLocation URL.
@interface DocSetOutlineController : UITableViewController

/// The DocSet URL from which extract the book URL.
@property (nonatomic, strong) NSURL *docSetURL;

/// The book.json path derived from the DocSet URL.
@property (nonatomic, strong, readonly) NSString *bookJSONPath;

@end


/// Item to represent a deserialized outline item
@interface DocSetOutlineItem : NSObject {
  NSString *title;
	NSString *aref;
	NSString *href;
	NSArray *children;
	BOOL expanded;
	int level;
}

@property (nonatomic) BOOL expanded;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *aref;
@property (nonatomic, strong, readonly) NSString *href;
@property (nonatomic, readonly) int level;
@property (nonatomic, strong, readonly) NSArray *children;

- (id)initWithDictionary:(NSDictionary *)outlineInfo level:(int)outlineLevel;
- (NSArray *)flattenedChildren;
- (void)addOpenChildren:(NSMutableArray *)list;

@end


/// Cell to show a disclosable outline item
@interface DocSetOutlineCell : UITableViewCell {
	__weak id delegate;
	DocSetOutlineItem *outlineItem;
	UIButton *outlineDisclosureButton;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) DocSetOutlineItem *outlineItem;

@end


@interface NSObject (DocSetOutlineCellDelegate)

- (void)docSetOutlineCellDidTapDisclosureButton:(DocSetOutlineCell *)cell;

@end
