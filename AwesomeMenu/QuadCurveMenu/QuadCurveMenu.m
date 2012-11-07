//
//  QuadCurveMenu.m
//  AwesomeMenu
//
//  Created by Levey on 11/30/11.
//  Copyright (c) 2011 lunaapp.com. All rights reserved.
//

#import "QuadCurveMenu.h"


#define NEARRADIUS 110.0f
#define ENDRADIUS 100.0f
#define FARRADIUS 120.0f
#define STARTPOINT CGPointMake(25, 360)
#define TIMEOFFSET 0.036f
#define ROTATEANGLE 0
#define MENUWHOLEANGLE  1.83259571
#define MENUITEMSEPERATION 8.f

static CGPoint RotateCGPointAroundCenter(CGPoint point, CGPoint center, float angle)
{
   CGAffineTransform translation = CGAffineTransformMakeTranslation(center.x, center.y);
   CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
   CGAffineTransform transformGroup = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformInvert(translation), rotation), translation);
   return CGPointApplyAffineTransform(point, transformGroup);    
}

@interface QuadCurveMenu ()

- (void)_close;
- (void)_expand;
- (CAAnimationGroup *)_blowupAnimationAtPoint:(CGPoint)p;
- (CAAnimationGroup *)_shrinkAnimationAtPoint:(CGPoint)p;
-(void)adjustMenuItemEndpoint:(QuadCurveMenuItem*)item count:(int)count index:(int)i;
@end

@implementation QuadCurveMenu
@synthesize expanding = _expanding;
@synthesize delegate = _delegate;
@synthesize menusArray = _menusArray;
@synthesize startPoint = _startPoint;
@synthesize allowTapToClose = _allowTapToClose;
@synthesize expandMethod;

#pragma mark - initialization & cleaning up
- (id)initWithFrame:(CGRect)frame menus:(NSArray *)aMenusArray
{
   self = [super initWithFrame:frame];
   if (self) {
      self.backgroundColor = [UIColor clearColor];
      
      // layout menus
      self.startPoint = STARTPOINT;
      self.menusArray = aMenusArray;
      
      // add the "Add" Button.
      _addButton = [[QuadCurveMenuItem alloc] initWithImage:[UIImage imageNamed:@"bg-addbutton.png"]
                                           highlightedImage:[UIImage imageNamed:@"bg-addbutton-highlighted.png"] 
                                               ContentImage:[UIImage imageNamed:@"icon-plus.png"] 
                                    highlightedContentImage:[UIImage imageNamed:@"icon-plus-highlighted.png"]];
      _addButton.delegate = self;
      
      _addButton.center = self.startPoint;
      self.allowTapToClose = YES;
      _flag = -1;
      [self addSubview:_addButton];
   }
   return self;
}

-(void)setStartPoint:(CGPoint)startPoint
{
   _startPoint = startPoint;
   _addButton.startPoint = startPoint;
   _addButton.center = startPoint;
   
   int i=0;
   for( QuadCurveMenuItem *item in _menusArray )
   {      
      item.startPoint = startPoint;
      [self adjustMenuItemEndpoint:item count:[_menusArray count] index:i];
      i++;
      
      if( self.isExpanding )
      {
         item.center = item.endPoint;
      }
   }
   
}

-(void)setExpandMethod:(QuadCurveExpandMethod)newExpandMethod
{
   expandMethod = newExpandMethod;
   int i=0;
   for( QuadCurveMenuItem *item in _menusArray )
   {      
      item.startPoint = self.startPoint;
      [self adjustMenuItemEndpoint:item count:[_menusArray count] index:i];
      i++;
      
      if( self.isExpanding )
      {
         item.center = item.endPoint;
      }
   }
}

- (void)dealloc
{
   [_addButton release];
   [_menusArray release];
   [super dealloc];
}


#pragma mark - UIView's methods
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
   // if the menu state is expanding, everywhere can be touch
   // otherwise, only the add button are can be touch
   if (YES == _expanding && self.allowTapToClose) 
   {
      return YES;
   }
   else if( !self.expanding && !self.allowTapToClose )
   {
      return CGRectContainsPoint(_addButton.frame, point);
   }
   else
   {
      BOOL touchedAButton = CGRectContainsPoint(_addButton.frame, point);;
      for( QuadCurveMenuItem *item in self.menusArray )
      {
         if( CGRectContainsPoint(item.frame, point) )
         {
            touchedAButton = YES;
         }
      }
      
      return touchedAButton;
   }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   self.expanding = !self.isExpanding;
}

#pragma mark - QuadCurveMenuItem delegates

-(void)openMenu
{
   if( !self.expanding )
   {
      self.expanding = YES;
   }
}

-(void)closeMenu
{
   if( self.expanding )
   {
      self.expanding = NO;
   }
}

- (void)quadCurveMenuItemTouchesBegan:(QuadCurveMenuItem *)item
{
   if (item == _addButton) 
   {
      self.expanding = !self.isExpanding;
   }
}
- (void)quadCurveMenuItemTouchesEnd:(QuadCurveMenuItem *)item
{
   // exclude the "add" button
   if (item == _addButton) 
   {
      return;
   }
   // blowup the selected menu button
   CAAnimationGroup *blowup = [self _blowupAnimationAtPoint:item.center];
   [item.layer addAnimation:blowup forKey:@"blowup"];
   item.center = item.startPoint;
   
   // shrink other menu buttons
   for (int i = 0; i < [_menusArray count]; i ++)
   {
      QuadCurveMenuItem *otherItem = [_menusArray objectAtIndex:i];
      CAAnimationGroup *shrink = [self _shrinkAnimationAtPoint:otherItem.center];
      if (otherItem.tag == item.tag) {
         continue;
      }
      [otherItem.layer addAnimation:shrink forKey:@"shrink"];
      
      otherItem.center = otherItem.startPoint;
   }
   _expanding = NO;
   
   // rotate "add" button
   float angle = self.isExpanding ? -M_PI_4 : 0.0f;
   [UIView animateWithDuration:0.2f animations:^{
      _addButton.transform = CGAffineTransformMakeRotation(angle);
   }];
   
   if ([_delegate respondsToSelector:@selector(quadCurveMenu:didSelectIndex:)])
   {
      [_delegate quadCurveMenu:self didSelectIndex:item.tag - 1000];
   }
}

#pragma mark - instant methods

-(void)adjustMenuItemEndpoint:(QuadCurveMenuItem*)item count:(int)count index:(int)i
{
   float separation = item.bounds.size.width + MENUITEMSEPERATION;

   item.startPoint = self.startPoint;
   item.center = item.startPoint;
   
   switch (self.expandMethod) {
      case QuadCurveExpandMethodReverseLine:
      {
         CGPoint endPoint = CGPointMake(self.startPoint.x - ( (i + 1) * separation) , self.startPoint.y);
         item.endPoint = endPoint;
         item.nearPoint = CGPointMake( endPoint.x + MENUITEMSEPERATION, endPoint.y );
         item.farPoint = endPoint;
         break;
      }
      case QuadCurveExpandMethodLine:
      {
         CGPoint endPoint = CGPointMake(self.startPoint.x + ( (i + 1) * separation) , self.startPoint.y);
         item.endPoint = endPoint;
         item.nearPoint = CGPointMake( endPoint.x - MENUITEMSEPERATION, endPoint.y );
         item.farPoint = endPoint;
         break;
      }
      default:
      case QuadCurveExpandMethodCircle:
      {
         CGPoint endPoint = CGPointMake(self.startPoint.x + ENDRADIUS * sinf(i * MENUWHOLEANGLE / count), self.startPoint.y - ENDRADIUS * cosf(i * MENUWHOLEANGLE / count));
         item.endPoint = RotateCGPointAroundCenter(endPoint, self.startPoint, ROTATEANGLE);
         CGPoint nearPoint = CGPointMake(self.startPoint.x + NEARRADIUS * sinf(i * MENUWHOLEANGLE / count), self.startPoint.y - NEARRADIUS * cosf(i * MENUWHOLEANGLE / count));
         item.nearPoint = RotateCGPointAroundCenter(nearPoint, self.startPoint, ROTATEANGLE);
         CGPoint farPoint = CGPointMake(self.startPoint.x + FARRADIUS * sinf(i * MENUWHOLEANGLE / count), self.startPoint.y - FARRADIUS * cosf(i * MENUWHOLEANGLE / count));
         item.farPoint = RotateCGPointAroundCenter(farPoint, self.startPoint, ROTATEANGLE);  
         break;
      } 
   }

}

- (void)setMenusArray:(NSArray *)aMenusArray
{
   if (aMenusArray == _menusArray)
   {
      return;
   }
   [_menusArray release];
   _menusArray = [aMenusArray copy];
   
   
   // clean subviews
   for (UIView *v in self.subviews) 
   {
      if (v.tag >= 1000) 
      {
         [v removeFromSuperview];
      }
   }
   // add the menu buttons
   int count = [_menusArray count];
   for (int i = 0; i < count; i ++)
   {
      QuadCurveMenuItem *item = [_menusArray objectAtIndex:i];
      item.tag = 1000 + i;
      [self adjustMenuItemEndpoint:item count:count index:i];
      item.delegate = self;
      [self addSubview:item];
   }
}
- (BOOL)isExpanding
{
   return _expanding;
}

- (void)setExpanding:(BOOL)expanding
{
   if( _flag != [_menusArray count] && _flag != -1 )
      return;
   
   _expanding = expanding; 
   
   
   
   // rotate add button
   float angle = self.isExpanding ? -M_PI_4 : 0.0f;
   [UIView animateWithDuration:0.2f animations:^{
      _addButton.transform = CGAffineTransformMakeRotation(angle);
   }];
   
   if ( self.hideWhenClosed )
   {
      float startDelay = self.isExpanding ? 0.f : 0.35f;
      [UIView animateWithDuration:0.25 delay:startDelay options:UIViewAnimationCurveEaseIn animations:^{
         self.alpha = self.isExpanding ? 1.f : 0.f;
      } completion:nil];
   }
   
   // expand or close animation
   if (!_timer) 
   {
      _flag = self.isExpanding ? 0 : ([_menusArray count] - 1);
      SEL selector = self.isExpanding ? @selector(_expand) : @selector(_close);
      _timer = [[NSTimer scheduledTimerWithTimeInterval:TIMEOFFSET target:self selector:selector userInfo:nil repeats:YES] retain];
   }
}
#pragma mark - private methods
- (void)_expand
{
   if (_flag == [_menusArray count])
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
      return;
   }
   
   int tag = 1000 + _flag;
   QuadCurveMenuItem *item = (QuadCurveMenuItem *)[self viewWithTag:tag];
   
   CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
   rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:M_PI],[NSNumber numberWithFloat:0.0f], nil];
   rotateAnimation.duration = 0.5f;
   rotateAnimation.keyTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:.3], 
                               [NSNumber numberWithFloat:.4], nil]; 
   
   CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
   positionAnimation.duration = 0.5f;
   CGMutablePathRef path = CGPathCreateMutable();
   CGPathMoveToPoint(path, NULL, item.startPoint.x, item.startPoint.y);
   CGPathAddLineToPoint(path, NULL, item.farPoint.x, item.farPoint.y);
   CGPathAddLineToPoint(path, NULL, item.nearPoint.x, item.nearPoint.y); 
   CGPathAddLineToPoint(path, NULL, item.endPoint.x, item.endPoint.y); 
   positionAnimation.path = path;
   CGPathRelease(path);
   
   CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
   animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, rotateAnimation, nil];
   animationgroup.duration = 0.5f;
   animationgroup.fillMode = kCAFillModeForwards;
   animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
   
   [item.layer addAnimation:animationgroup forKey:@"Expand"];
   item.center = item.endPoint;
   
   _flag ++;
   
   
   
}

- (void)_close
{
   if (_flag == -1)
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
      return;
   }
   
   int tag = 1000 + _flag;
   QuadCurveMenuItem *item = (QuadCurveMenuItem *)[self viewWithTag:tag];
   
   CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
   rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],[NSNumber numberWithFloat:M_PI * 2],[NSNumber numberWithFloat:0.0f], nil];
   rotateAnimation.duration = 0.5f;
   rotateAnimation.keyTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:.0], 
                               [NSNumber numberWithFloat:.4],
                               [NSNumber numberWithFloat:.5], nil]; 
   
   CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
   positionAnimation.duration = 0.5f;
   CGMutablePathRef path = CGPathCreateMutable();
   CGPathMoveToPoint(path, NULL, item.endPoint.x, item.endPoint.y);
   CGPathAddLineToPoint(path, NULL, item.farPoint.x, item.farPoint.y);
   CGPathAddLineToPoint(path, NULL, item.startPoint.x, item.startPoint.y); 
   positionAnimation.path = path;
   CGPathRelease(path);
   
   CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
   animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, rotateAnimation, nil];
   animationgroup.duration = 0.5f;
   animationgroup.fillMode = kCAFillModeForwards;
   animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
   [item.layer addAnimation:animationgroup forKey:@"Close"];
   item.center = item.startPoint;
   _flag --;
}

- (CAAnimationGroup *)_blowupAnimationAtPoint:(CGPoint)p
{
   CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
   positionAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p], nil];
   positionAnimation.keyTimes = [NSArray arrayWithObjects: [NSNumber numberWithFloat:.3], nil]; 
   
   CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
   scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(3, 3, 1)];
   
   CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
   opacityAnimation.toValue  = [NSNumber numberWithFloat:0.0f];
   
   CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
   animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, scaleAnimation, opacityAnimation, nil];
   animationgroup.duration = 0.3f;
   animationgroup.fillMode = kCAFillModeForwards;
   
   return animationgroup;
}

- (CAAnimationGroup *)_shrinkAnimationAtPoint:(CGPoint)p
{
   CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
   positionAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p], nil];
   positionAnimation.keyTimes = [NSArray arrayWithObjects: [NSNumber numberWithFloat:.3], nil]; 
   
   CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
   scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.01, .01, 1)];
   
   CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
   opacityAnimation.toValue  = [NSNumber numberWithFloat:0.0f];
   
   CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
   animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, scaleAnimation, opacityAnimation, nil];
   animationgroup.duration = 0.3f;
   animationgroup.fillMode = kCAFillModeForwards;
   
   return animationgroup;
}


@end
