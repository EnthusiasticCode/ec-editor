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
	[RACAble(self.item) subscribeNext:^(FileSystemItem *item) {
    @strongify(self);
		
		NSURL *url = item.url;
		
		self.textLabel.text = url.lastPathComponent;
		if (style == UITableViewCellStyleSubtitle) {
			self.detailTextLabel.text = [[[ArtCodeProjectSet defaultSet] relativePathForFileURL:url] prettyPath];
		}

		if ([item isKindOfClass:FileSystemDirectory.class]) {
			self.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
			self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			self.imageView.image = [UIImage styleDocumentImageWithFileExtension:url.pathExtension];
			self.accessoryType = UITableViewCellAccessoryNone;
		}
	}];

  return self;
}

- (void)prepareForReuse {
	self.item = nil;
}

@end
