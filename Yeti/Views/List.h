//
//  List.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Content.h"
#import "Paragraph.h"

typedef NS_ENUM(NSInteger) {
    UnorderedList,
    OrderedList
} ListType;

@interface List : Paragraph

@property (nonatomic, assign, getter=isQuoted) BOOL quoted;
@property (nonatomic) ListType type;

- (NSAttributedString *)processContent:(Content *)content;

- (void)setContent:(Content *)content;

@end
