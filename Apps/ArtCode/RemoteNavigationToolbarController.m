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

- (RACSubscribable *)buttonsActionSubscribable {
  return _buttonsActionSubject ?: (_buttonsActionSubject = [RACSubject subject]);
}

- (IBAction)taggedButtonAction:(id)sender {
  [_buttonsActionSubject sendNext:sender];
}

- (void)viewDidUnload {
    [self setRemoteDeleteButton:nil];
    [super viewDidUnload];
}
@end
