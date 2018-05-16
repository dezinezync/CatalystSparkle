//
//  SearchResults.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SearchResults.h"

@interface SearchResults () <DZDatasource>

@end

@implementation SearchResults

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
}



@end
