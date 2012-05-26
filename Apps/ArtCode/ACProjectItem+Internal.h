//
//  ACProjectItem+Internal.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class ACProject;

@interface ACProjectItem (Internal)

/// Designed initalizer. Initialize the item from a property list dictionary.
/// Subclasses must override this and call [self setPropertyListDictionary:plistDictionary] within it.
- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary;

/// Encode the item in a property list dictionary.
- (NSDictionary *)propertyListDictionary;
/// Decode and load the item's metadata from a property list dictionary.
- (void)setPropertyListDictionary:(NSDictionary *)propertyListDictionary;

@end
