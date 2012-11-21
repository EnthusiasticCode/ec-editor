//
//  RemoteNavigationToolbarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/10/12.
//
//

#import "RemoteNavigationToolbarController.h"


@implementation RemoteNavigationToolbarController {
  RACSubject *_buttonsActionSubject;
}

- (RACSignal *)buttonsActionSignal {
  return _buttonsActionSubject ?: (_buttonsActionSubject = [RACSubject subject]);
}

- (IBAction)taggedButtonAction:(id)sender {
  [_buttonsActionSubject sendNext:sender];
}

- (void)viewDidUnload {
    [self setRemoteDeleteButton:nil];
    [self setDoneButton:nil];
    [super viewDidUnload];
}
@end
