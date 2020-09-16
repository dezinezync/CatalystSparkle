//
//  GalleryCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 30/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "GalleryCell.h"

NSString *const kGalleryCell = @"com.yeti.cell.gallery";

@implementation GalleryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.downloadTask) {
        [self.downloadTask cancel];
        self.downloadTask = nil;
    }
    
    self.imageView.image = nil;
}

@end
