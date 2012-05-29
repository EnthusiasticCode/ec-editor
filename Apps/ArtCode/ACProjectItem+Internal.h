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

@end
