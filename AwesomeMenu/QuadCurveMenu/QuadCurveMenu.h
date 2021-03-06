//
//  QuadCurveMenu.h
//  AwesomeMenu
//
//  Created by Levey on 11/30/11.
//  Copyright (c) 2011 lunaapp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuadCurveMenuItem.h"
#import <QuartzCore/QuartzCore.h>

@protocol QuadCurveMenuDelegate;

typedef enum {
   QuadCurveExpandMethodCircle,
   QuadCurveExpandMethodLine,
   QuadCurveExpandMethodReverseLine,
} QuadCurveExpandMethod;

@interface QuadCurveMenu : UIView <QuadCurveMenuItemDelegate>
{
   NSArray *_menusArray;
   int _flag;
   NSTimer *_timer;
   QuadCurveMenuItem *_addButton;
   
   id<QuadCurveMenuDelegate> _delegate;
   
}
@property (nonatomic, copy) NSArray *menusArray;
@property (nonatomic, getter = isExpanding)     BOOL expanding;
@property (nonatomic, assign) id<QuadCurveMenuDelegate> delegate;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) BOOL allowTapToClose;
@property (nonatomic, assign) QuadCurveExpandMethod expandMethod;
@property (nonatomic, assign) BOOL hideWhenClosed;

- (id)initWithFrame:(CGRect)frame menus:(NSArray *)aMenusArray;
- (void)openMenu;
- (void)closeMenu;

@end

@protocol QuadCurveMenuDelegate <NSObject>
- (void)quadCurveMenu:(QuadCurveMenu *)menu didSelectIndex:(NSInteger)idx;
@end