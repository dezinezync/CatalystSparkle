//
//  TwoFingerPanGestureRecognizer.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TwoFingerPanGestureRecognizer.h"

@interface TwoFingerPanGestureRecognizer ()

@property (nonatomic, strong) NSMutableArray <NSValue *> *firstTouchedPoints;
@property (nonatomic, strong) NSMutableArray <NSValue *> *secondTouchedPoints;

@end

@implementation TwoFingerPanGestureRecognizer

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        [self setup];
    }
    
    return self;
}

- (void)reset {
#ifdef DEBUG
    NSLog(@"Resetting two finger swipe");
#endif
    
    [super reset];
    
    [self setup];
    
}

- (void)setup {
#ifdef DEBUG
    NSLog(@"Setting up two finger swipe");
#endif
    
    self.state = UIGestureRecognizerStatePossible;
    self.firstTouchedPoints = [NSMutableArray array];
    self.secondTouchedPoints = [NSMutableArray array];
    self.direction = TwoFingerPanUnknown;
}

#pragma mark - Overrides

- (BOOL)cancelsTouchesInView {
    return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    
    if (touches.count >= 1) {
        self.state = UIGestureRecognizerStateBegan;
#ifdef DEBUG
        NSLog(@"Beginning two finger swipe");
#endif
        return;
    }
    
    self.state = UIGestureRecognizerStateFailed;
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesMoved:touches withEvent:event];
    
    if (self.state == UIGestureRecognizerStateFailed || touches.count != 2) {
        return;
    }
    
#ifdef DEBUG
    NSLog(@"Moving two finger swipe");
#endif
    UIWindow *window = self.view.window;
    NSArray <UITouch *> *arrayOfTouches = [touches allObjects];
    
    // First Finger
    CGPoint location = [[arrayOfTouches firstObject] locationInView:window];
    
    if (CGPointEqualToPoint(location, CGPointZero) == NO) {
        [self.firstTouchedPoints addObject:[NSValue valueWithCGPoint:location]];
        self.state = UIGestureRecognizerStateChanged;
    }
    
    location = [[arrayOfTouches lastObject] locationInView:window];
    
    if (CGPointEqualToPoint(location, CGPointZero) == NO) {
        [self.secondTouchedPoints addObject:[NSValue valueWithCGPoint:location]];
        self.state = UIGestureRecognizerStateChanged;
    }
    
    if ([self twoFingersMoveUp]) {
        self.direction = TwoFingerPanUp;
    }
    else if ([self twoFingersMoveDown]) {
        self.direction = TwoFingerPanDown;
    }
    else {
        self.direction = TwoFingerPanUnknown;
    }
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesEnded:touches withEvent:event];
#ifdef DEBUG
    NSLog(@"Ended two finger swipe");
#endif
    
    if ([self twoFingersMoveUp]) {
        self.direction = TwoFingerPanUp;
        self.state = UIGestureRecognizerStateRecognized;
    }
    else if ([self twoFingersMoveDown]) {
        self.direction = TwoFingerPanDown;
        self.state = UIGestureRecognizerStateRecognized;
    }
    else {
        self.state = UIGestureRecognizerStateFailed;
    }
    
}

#pragma mark - Helpers

- (BOOL)twoFingersMoveUp {
    
    BOOL firstFingerWasMovedUp = NO;
    BOOL secondFingerWasMovedUp = NO;
    
    if (self.firstTouchedPoints.count > 1
        && [self.firstTouchedPoints.firstObject CGPointValue].y > [self.firstTouchedPoints.lastObject CGPointValue].y) {
        
        firstFingerWasMovedUp = YES;
        
    }
    
    if (self.secondTouchedPoints.count > 1
        && [self.secondTouchedPoints.firstObject CGPointValue].y > [self.secondTouchedPoints.lastObject CGPointValue].y) {
        
        secondFingerWasMovedUp = YES;
        
    }
    
    return firstFingerWasMovedUp && secondFingerWasMovedUp;
    
}

- (BOOL)twoFingersMoveDown {
    
    BOOL firstFingerWasMovedDown = NO;
    BOOL secondFingerWasMovedDown = NO;
    
    if (self.firstTouchedPoints.count > 1
        && [self.firstTouchedPoints.firstObject CGPointValue].y < [self.firstTouchedPoints.lastObject CGPointValue].y) {
        
        firstFingerWasMovedDown = YES;
        
    }
    
    if (self.secondTouchedPoints.count > 1
        && [self.secondTouchedPoints.firstObject CGPointValue].y < [self.secondTouchedPoints.lastObject CGPointValue].y) {
        
        secondFingerWasMovedDown = YES;
        
    }
    
    return firstFingerWasMovedDown && secondFingerWasMovedDown;
    
}


@end
