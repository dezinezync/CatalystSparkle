//
//  FolderCell.m
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FolderCell.h"

@interface FolderCell ()

@property (nonatomic, copy, readwrite) NSNumber *folderID;

@end

@implementation FolderCell

- (void)configure:(Folder *)item indexPath:(NSIndexPath *)indexPath {
    
    self.folder = item;
    
    if (self.folder == nil) {
        return;
    }
    
    UIListContentConfiguration *content = [UIListContentConfiguration sidebarHeaderConfiguration];
    
    content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    content.text = item.title;
    
    if (SharedPrefs.showUnreadCounts == YES) {
        
        item.unreadCountObservor = self;
        
        if (item.unreadCount.unsignedIntegerValue > 0) {
            
            content.secondaryText = item.unreadCount.stringValue;
            
        }
        
        content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
        
    }
    
    content.prefersSideBySideTextAndSecondaryText = YES;
    
    NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
    
    NSString *imageName = [snapshot isExpanded:item] ? @"folder" : @"folder.fill";
    
    content.image = [UIImage systemImageNamed:imageName];
    
    content.imageProperties.maximumSize = CGSizeMake(24.f, 24.f);
    
    self.contentConfiguration = content;
    
    UICellAccessoryOutlineDisclosure *disclosure = [UICellAccessoryOutlineDisclosure new];
    
    disclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
    
    self.accessories = @[disclosure];
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *updatedContent = (id)[self contentConfiguration];
    
    if (state.isExpanded == YES) {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder"];
        
    }
    else {
        
        updatedContent.image = [UIImage systemImageNamed:@"folder.fill"];
        
    }
    
    self.contentConfiguration = updatedContent;
    
}

- (void)unreadCountChangedTo:(NSNumber *)count {
    
    if (self.DS == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [self.DS indexPathForItemIdentifier:self.folder];
    
    if (indexPath == nil) {
        return;
    }
    
    @try {
        NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
        
        [snapshot reloadItemsWithIdentifiers:@[self.folder]];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
    }
    @catch (NSException *exception) {
        
    }
    
}

@end
