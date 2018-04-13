//
//  Code.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Paragraph.h"

@interface Code : UIView

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UILabel *label;

- (void)setAttributedText:(NSAttributedString *)attrs;

@end
