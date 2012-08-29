//
//  QuickFileHighlightTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/08/12.
//
//

#import "QuickFileHighlightTableController.h"
#import "QuickBrowsersContainerController.h"

#import "CodeFileController.h"
#import "TMUnit.h"
#import "TMSyntaxNode.h"

@interface QuickFileHighlightTableController ()

@property (nonatomic, strong, readonly) NSArray *syntaxNames;
@property (nonatomic, strong) NSString *currentSyntaxName;

@end

@implementation QuickFileHighlightTableController {
  NSArray *_syntaxNames;
}

- (NSArray *)syntaxNames {
  if (!_syntaxNames) {
    _syntaxNames = [[TMSyntaxNode allSyntaxesNames].allKeys sortedArrayUsingSelector:@selector(compare:)];
  }
  return _syntaxNames;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.currentSyntaxName = self.codeFileController.codeUnit.syntax.name;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.syntaxNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
  cell.textLabel.text = [self.syntaxNames objectAtIndex:indexPath.row];
  if ([cell.textLabel.text isEqualToString:self.currentSyntaxName]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }
    
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
