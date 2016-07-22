//
//  JTPlayerTank.m
//  tanks
//
//  Created by TemaMarti on 09.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import "JTPlayerTank.h"
#import "JTGameScene.h"
#import "JTBullet.h"

#define bullet_tag 1235
#define trace_delay 0.08
#define offset_y 15
#define trace_duration 10

//скорость танка
@interface JTPlayerTank()
@property(nonatomic, assign) float speed;
@property(nonatomic, assign) float traceCounter;
@property(nonatomic, strong) CCNode *pretender;

@end

@implementation JTPlayerTank

-(id) initWithSprite:(CCSprite *)sprt scene:(JTGameScene *)scene properties:(NSDictionary *)props {
    
    if (self = [super initWithSprite:sprt scene:scene properties:props]) {
        
        _speed = 65;
        _traceCounter = 0;
        
        //место где встанет танк, если есть препятствие
        _pretender = [CCNode node];
    }
    
    return self;
}

-(void) check:(NSArray*)array forBool:(BOOL*)b andWall:(CCSprite*)wall {
    
    for (NSValue *val in array) {
        
        if (CGRectContainsPoint([self.scene getRectFromSprite:wall], [val CGPointValue])) {
            *b = NO;
        }
    }
}

//действия нашего танка
-(void) update:(float)dt {
    
    //переводим угол танка в радианы
    float rad = self.rotation * (M_PI / 180);
    
    //deltaPoint - эта точка, на которую танк сместится в случае отсутствия препятствия
    CGPoint deltaPoint = CGPointZero;
    
    //вычисление deltaPoint в зависимости от угла танка в направлени движения
    if (self.scene.isMovingForward) deltaPoint = ccp(sin(rad) * dt *_speed, cos(rad) * dt * _speed);
    else if (self.scene.isMovingBack) deltaPoint = ccp(-sin(rad) * dt *_speed, -cos(rad) * dt * _speed);
    
    //претенденту присваивается предпологаемая новая позиция танка
    _pretender.position = ccpAdd(self.position, deltaPoint);
    
    //.......предпологаемый новый угол танка
    if (self.scene.isRotatingLeft) _pretender.rotation = self.rotation - 1 * dt * (_speed/2);
    else if (self.scene.isRotatingRight) _pretender.rotation = self.rotation + 1 * dt * (_speed/2);
    
    //новые булевые проверкидля проверки каждого конкретного движения и присваевается им положительное значение
    BOOL canMoveForward = YES;
    BOOL canMoveBack = YES;
    BOOL canRotLeft = YES;
    BOOL canRotRight = YES;
    
    //на претенденте, который имеет и позицию, и угол, как у танка строятся 2 линии из точек (вверху и внизу)
    //потом эти точки ковертируются в мировое пространство  и к ним прибовляется deltaPoint
    //создаются 2 массива для тоек верхней линии и нижний
    //точки верхней линии будут повторяться на столкновении при движении вперед, точки нижней - при движении назад
    float  muzzleOffset = 6;//дуло танка 6пикселей
    
    NSMutableArray *topArray = [NSMutableArray array];
    NSMutableArray *bottomArray = [NSMutableArray array];
    
    for (int x = -self.sprite.contentSize.width/2; x <= self.sprite.contentSize.width/2; x += self.sprite.contentSize.width/4) {
        for (int y = self.sprite.contentSize.height/2 - muzzleOffset; y >= -self.sprite.contentSize.height/2;
             y -= (self.sprite.contentSize.height - muzzleOffset)) {
            CGPoint p1 = ccpAdd(deltaPoint, [_pretender convertToWorldSpace:ccp(x, y)]);
            
            if (y == self.sprite.contentSize.height/2 - muzzleOffset) [topArray addObject:[NSValue valueWithCGPoint:p1]];
            else                                                      [bottomArray addObject:[NSValue valueWithCGPoint:p1]];
            
            //если раскоментировать то можно увидеть эти точки
            /*CGRect rect = CGRectMake(p1.x, p1.y, 2, 2);
            CCLayerColor *ll = [CCLayerColor layerWithColor:ccc4(255, 0, 0, 80) width:rect.size.width height:rect.size.height];
            ll.position = ccp(rect.origin.x, rect.origin.y);
            [self.scene addChild:ll z:1000];*/
        }
    }
    
    //в этом цикле перебираются все препятствия и проверяется соприкасаются ли препятствия с линиями из точек
    for (CCSprite *wall in self.scene.wallsArray) {
        //если соприкасаются, то булевые движения будут включены
        if (self.scene.isMovingForward) [self check:topArray forBool:&canMoveForward andWall:wall];
        else if (self.scene.isMovingBack) [self check:bottomArray forBool:&canMoveBack andWall:wall];
        else if (self.scene.isRotatingLeft) {
            //для проверки поворотов точки верхней и нижней линии объединяются
            [topArray addObjectsFromArray:bottomArray];
            [self check:topArray forBool:&canRotLeft andWall:wall];
            
        } else if (self.scene.isRotatingRight) {
            [topArray addObjectsFromArray:bottomArray];
            [self check:topArray forBool:&canRotRight andWall:wall];
        }
    }
    
    topArray = nil;
    bottomArray = nil;
    
    //проверка на края экрана, если прямоугольник претендента не вылазит за края экрана, то танк едет
    if (_pretender.position.x - self.sprite.contentSize.width/2 > 0 &&
        _pretender.position.x + self.sprite.contentSize.width/2 < self.winSize.width &&
        _pretender.position.y - self.sprite.contentSize.height/2 > 0 &&
        _pretender.position.y + self.sprite.contentSize.height/2 < self.winSize.height) {
        
        //если двигались вперед и булевая движения вперед не была выключена или если двигались назад и булевая движения назад не была выключена
        //то присваеваем танку позицию претендента
        
        if ((self.scene.isMovingForward && canMoveForward) || (self.scene.isMovingBack && canMoveBack))
            self.position = _pretender.position;
        
        //если булевая возвращалась влево и булевая вращения влево не была включена или если вращались вправо и булевая вращения вправо не была
        //включена, то присваеваем таку угол претендента
        
        if ((self.scene.isRotatingLeft && canRotLeft) || (self.scene.isRotatingRight && canRotRight))
            self.rotation = _pretender.rotation;
        
        //следы
        float offseY = 0;
        
        if (self.scene.isMovingForward) offseY = -offset_y;
        else if (self.scene.isMovingBack) offseY = offset_y-6;
        
        _traceCounter += dt;
        
        if (_traceCounter > trace_delay) {
            
            _traceCounter = 0;
            
            CCSprite *traces = [CCSprite spriteWithFile:@"traces.png"];
            traces.position = [self convertToWorldSpace:ccp(0, offseY)];
            traces.rotation = self.rotation;
            [self.scene addChild:traces];
            
            id fade = [CCFadeOut actionWithDuration:trace_duration];
            id cal = [CCCallBlock actionWithBlock:^{
                [traces removeFromParentAndCleanup:YES];
            }];
            [traces runAction:[CCSequence actions:fade, cal, nil]];
        }
    }
}

-(void) shoot{
    
   //ограничиваем частоту выстрела
    if ([self.scene getChildByTag:bullet_tag] == nil) {
    //выстрел из самого танка
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:self.rotation], key_rotation,
                           [NSValue valueWithCGPoint:[self convertToWorldSpace:ccp(0, 20)]], key_position, nil];
                          
    //создание имитации выстрела в координате (0; 0)
    JTBullet *bullet = [[JTBullet alloc] initWithSprite:[CCSprite spriteWithFile:@"shot.png"] scene:self.scene properties:dict];
    bullet.tag = bullet_tag;
    [self.scene addChild:bullet z:20];
    }
}

@end
