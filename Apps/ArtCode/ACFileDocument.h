//
//  ACFileDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECAttributedUTF8FileBuffer;

@interface ACFileDocument : UIDocument

- (ECAttributedUTF8FileBuffer *)fileBuffer;

@end
