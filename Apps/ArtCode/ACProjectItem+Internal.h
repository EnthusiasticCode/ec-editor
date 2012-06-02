//
//  ACProjectItem+Internal.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class ACProject;

@interface ACProjectItem (Internal)

/// A plist encodable dictionary representing the item's metadata
@property (nonatomic, strong) NSDictionary *propertyListDictionary;

/// Designed initalizer. Initialize the item from a property list dictionary.
/// Subclasses must override this and call [self setPropertyListDictionary:plistDictionary] within it.
- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary;

/// This method is called by the containing item when the receiver is about to be removed from the project.
/// Items should perform project related cleanup of contained items here, but they do not need to remove themselves from the project, as the containing item will provide to that.
- (void)prepareForRemoval;

@end
