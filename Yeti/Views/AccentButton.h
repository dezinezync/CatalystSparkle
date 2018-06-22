//
//  AccentButton.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccentButton : UIButton {
    BOOL _selected;
}

@property (nonatomic, weak) CAShapeLayer *borderLayer;

@end

NS_ASSUME_NONNULL_END
