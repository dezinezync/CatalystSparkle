//
//  AuthorVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"
#import "Author.h"

@interface AuthorVC : FeedVC

@property (nonatomic, weak) Author *author;

@end
