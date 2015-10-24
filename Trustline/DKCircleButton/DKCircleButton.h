
//
//  DKCircleButton.h
//  DKCircleButton
//
//  Created by Dmitry Klimkin on 23/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface DKCircleButton : UIButton

@property (nonatomic, strong) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable BOOL animateTap;
@property (nonatomic) IBInspectable BOOL displayShading;
@property (nonatomic) IBInspectable CGFloat borderSize;

- (void)blink;

- (void)setImage:(UIImage *)image animated: (BOOL)animated;

@end
