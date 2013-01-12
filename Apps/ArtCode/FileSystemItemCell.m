//
//  FileSystemItemCell.m
//  ArtCode
//
//  Created by Uri Baghin on 10/21/12.
//
//

#import "FileSystemItemCell.h"

#import "ArtCodeProjectSet.h"
#import "FileSystemFile.h"
#import "FileSystemDirectory.h"
#import "NSString+Utilities.h"
#import "UIImage+AppStyle.h"

@implementation FileSystemItemCell

#pragma mark UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self == nil) return nil;
	
	@weakify(self);
	[[[RACAble(self.item) map:^(FileSystemItem *item) {
		return item.urlSignal;
	}] switchToLatest] subscribeNext:^(NSURL *url) {
		ASSERT_MAIN_QUEUE();
    @strongify(self);
		
    self.textLabel.text = url.lastPathComponent;
		if (style == UITableViewCellStyleSubtitle) {
			self.detailTextLabel.text = [[[ArtCodeProjectSet defaultSet] relativePathForFileURL:url] prettyPath];
		}
		
		if ([self.item isKindOfClass:FileSystemFile.class]) {
			self.imageView.image = [UIImage styleDocumentImageWithFileExtension:url.pathExtension];
		}
	}];

  return self;
}

- (void)prepareForReuse {
	self.item = nil;
}

#pragma mark FileSystemItemCell

- (void)setItem:(FileSystemItem *)item {
	if (item == _item) return;
	_item = item;
	
	if ([item isKindOfClass:FileSystemDirectory.class]) {
		self.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	} else {
		self.imageView.image = [UIImage styleDocumentImageWithFileExtension:@""];
		self.accessoryType = UITableViewCellAccessoryNone;
		self.editingAccessoryType = UITableViewCellAccessoryNone;
	}
}

@end
