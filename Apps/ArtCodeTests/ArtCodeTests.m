//
//  ArtCodeTests.m
//  ArtCode
//
//  Created by Uri Baghin on 9/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTests.h"
#import "ACProject.h"


// this is just debug code so ignore the warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
void clearProjectsDirectory(void) {
  [ACProject performSelector:@selector(_removeAllProjects)];
}
#pragma clang diagnostic pop
