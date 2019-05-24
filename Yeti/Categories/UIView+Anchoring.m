//
//  UIView+Anchoring.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "UIView+Anchoring.h"

@implementation UIView (Anchoring)

- (void)anchorTo:(CGPoint)anchor {
    
    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchor.x, self.bounds.size.height * anchor.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y);
    
    CGPoint position = self.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    self.layer.position = position;
    self.layer.anchorPoint = anchor;
    
}

@end
