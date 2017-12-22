//
//  Gallery.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZKit/NibView.h>
#import "Content.h"

@interface Gallery : NibView

@property (nonatomic, weak) NSArray <Content *> *images;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, assign) NSInteger idx;

@end
