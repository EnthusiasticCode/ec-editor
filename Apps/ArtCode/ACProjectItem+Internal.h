//
//  ACProjectItem+Internal.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class ACProject;

@interface ACProjectItem (Internal)

#pragma mark Plist encoding

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary;
- (NSDictionary *)propertyListDictionary;

@end
