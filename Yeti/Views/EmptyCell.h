//
//  EmptyCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 10/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kEmptyCell;

@interface EmptyCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
