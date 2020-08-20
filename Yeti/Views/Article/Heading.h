//
//  Heading.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Paragraph.h"
#import "YetiTheme.h"

@interface Heading : Paragraph

@property (nonatomic, assign) NSInteger level;

@property (nonatomic, copy) NSString *identifier;

@end
