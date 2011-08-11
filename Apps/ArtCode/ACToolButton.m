//
//  ACToolButton.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 11/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolButton.h"

@implementation ACToolButton

@synthesize toolIdentifier;

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder]))
    {
        toolIdentifier = [self titleForState:UIControlStateDisabled];
        [self setTitle:@"" forState:UIControlStateDisabled];
    }
    return self;
}

@end
