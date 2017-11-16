//
//  List.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Content.h"

typedef NS_ENUM(NSInteger) {
    UnorderedList,
    OrderedList
} ListType;

@interface List : UIView

@property (nonatomic) ListType type;

- (void)setContent:(Content *)content;

@end
