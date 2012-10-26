//
//  FileSystemItemCell.m
//  ArtCode
//
//  Created by Uri Baghin on 10/21/12.
//
//

#import "FileSystemItemCell.h"
#import "FileSystemItem.h"
#import "UIImage+AppStyle.h"


@implementation FileSystemItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }
  @weakify(self);
  [[RACSubscribable combineLatest:@[[[RACAble(item) select:^id<RACSubscribable>(FileSystemItem *x) {
    return [RACSubscribable combineLatest:@[x.name, x.type]];
  }] switch], RACAbleWithStart(hitMask)]] subscribeNext:^(RACTuple *xs) {
    ASSERT_MAIN_QUEUE();
    @strongify(self);
    RACTuple *ys = xs.first;
    NSString *itemName = ys.first;
    NSString *type = ys.second;
    NSIndexSet *hitMask = xs.second;
    UITableViewCellAccessoryType accessoryType = self.accessoryType;
    self.textLabel.text = itemName;
    self.textLabelHighlightedCharacters = hitMask;
    // Crazy hack because UITableViewCell doesn't redraw properly if you change certain properties after it was inserted in a table view, unless you change it's accessoryType
    if (type == NSURLFileResourceTypeDirectory) {
      self.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
      if (accessoryType != UITableViewCellAccessoryNone) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = accessoryType;
      } else {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
    } else {
      self.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemName.pathExtension];
      if (accessoryType != UITableViewCellAccessoryNone) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryType = accessoryType;
      } else {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.accessoryType = UITableViewCellAccessoryNone;
      }
    }
  }];
  return self;
}

@end