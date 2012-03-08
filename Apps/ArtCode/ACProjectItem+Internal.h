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
- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary;

/// Encode the item in a propety list dictionary.
- (NSDictionary *)propertyListDictionary;

@end
