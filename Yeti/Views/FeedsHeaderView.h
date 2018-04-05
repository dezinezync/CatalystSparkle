//
//  FeedsHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 05/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

@interface FeedsHeaderView : NibView <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
