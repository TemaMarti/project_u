//
//  JTEnemyTank.m
//  tanks
//
//  Created by TemaMarti on 12.07.16.
//  Copyright TemaMarti 2016. All rights reserved.
//

#import "JTEnemyTank.h"
#import "JTGameScene.h"
#import "JTPlayerTank.h"
#import "JTBullet.h"


#define rot_speed 40         //ск вращения
#define move_speed 55        //ск движения
#define delay_after_shot 2   //задержка после выстрела


// типы щупов (линия из пиксилей, по которым танк будет искать дорогу)
typedef enum {

    JTProbeLeft = -1,
    JTProbeCenter = 0,
    JTProbeRight = 1
    
} JTProbe;

@interface JTEnemyTank ()
@property (nonatomic, assign) BOOL doChoose;
@property (nonatomic, assign) float shotDistance;
@property (nonatomic, assign) float dirX;
@property (nonatomic, assign) float dirY;
@end

@implementation JTEnemyTank

-(id) initWithSprite:(CCSprite *)sprite scene:(JTGameScene *)scene properties:(NSDictionary *)props {

    if (self = [super initWithSprite:sprite scene:scene properties:props]) {
        
        _doChoose = YES;
        
        self.shotDistance = [[props objectForKey:key_shot_distance] floatValue];
        self.position = [[props objectForKey:key_position] CGPointValue];
        
        _dirX = self.position.x;
        _dirY = self.position.y;
        
    }
    
    return self;
}

-(int) correctedRotation {

    // здесь мы коректируем угол. Дело в том, что угол может быть и больше 360 градусов, если танк долго вращается в одном направлении,
    // или может быть отрицательным, в таком случае -90  это 270
    // а нам нужно знать угол только от 0 до 360
    int rot = (int)self.rotation % 360;
    
    if (rot == -90) rot = 270;
    else if (rot == -270) rot = 90;
    else if (rot == -180) rot = 180;
    
    return rot;
}

-(CGRect) createProbe:(JTProbe) probe {
    
    // в этом методе мы создаем "щуп" (прямоугольник) с шириной 1 пиксел (фактически, это линия)
    // этим щупом мы будем проверять, есть ли впереди препятствие
    // или возможно там дружественный танк (чтобы не стрелять в друга)
    // всего будет 3 щупа: слева и справа для определения препятствий, и 1 по центру для определения друга
    
    // задаем первоначалную ширину и высоту щупа в 1 пиксель
    float lengthX = 1;
    float lengthY = 1;
    
    // если нужно создать щуп по центру танка, то ...
    if (probe == JTProbeCenter) {
        
        // берем скоректированный угол танка
        switch ([self correctedRotation]) {
            case 0:  lengthY =  _shotDistance;  break; // при угле 0 высота щупа станет равна положительной дистанции выстрела
            case 90: lengthX =  _shotDistance;  break; // при угле 90 ширина щупа станет равна положительной дистанции выстрела
            case 180:  lengthY =  -_shotDistance;  break; // при угле 180 высота щупа станет равна отрицательной дистанции выстрела
            case 270:  lengthX =  -_shotDistance;  break; // при угле 270 ширина щупа станет равна отрицательной дистанции выстрела
            default: break;
        }
        
        // иначе (для создания правого или левого щупа)
    } else {
    
        // если танк повернут вертикально, то высота щупа будет равна расстоянию от Y танка до Y позиции движения
        if ([self correctedRotation] == 0 || [self correctedRotation] == 180) {
            lengthY = _dirY - self.position.y;
            
            // если танк повернут горизонтально, то ширина щупа будет равна расстоянию от Х танка до Х позиции движения
        } else {
            lengthX = _dirX - self.position.x;
        }
    }
    
    // конвертируем позицию щупа в мировое пространство
    // так как значение щупов может быть -1 или 0 или 1 (смотри список вверху)
    // то щуп начнот рисоваться либо слева, либ по центру, либо справа от танка
    CGPoint local = [self convertToWorldSpace:ccp(probe * self.sprite.contentSize.width/2, self.sprite.contentSize.height/2)];
    
    // создаем щуп
    CGRect rect = CGRectMake(local.x, local.y, lengthX, lengthY);
    
    // если раскоментировать, то увидим щуп
    
  /*  CCLayerColor *ll = [CCLayerColor layerWithColor:ccc4(255, 0, 0, 255) width:rect.size.width height:rect.size.height];
    ll.position = ccp(rect.origin.x, rect.origin.y);
    [self.scene addChild:ll z:1000];*/
    
    return rect;
}

-(BOOL) isFriendAheadForProbe:(JTProbe) probe {
    
    // в этом методе мы определяем, не друг ли между нами и врагом
    // если друг, то стрелять нельзя
    
    // изначально определяем, что друга нет в зоне выстрела
    BOOL isFriend = NO;
    
    // проходим по всему массиву enemiesArray
    for (JTEnemyTank *tank in self.scene.enemiesArray) {
        
        // если танк из массива - это не self, то проверям его щупом
        if (![tank isEqual:self]) {
        
            // танк из массива конвертирует в мир позоцию своего спрайта
            CGPoint worldPoint = [tank convertToWorldSpace:tank.sprite.position];
            
            // создаем квадрат танка (так как не хотим заниматься сложными вычислениями)
            // при этом немного этот квадрат увеличиваем (делаем его чуть шире чем contentSize)
            CGRect rect = CGRectMake(worldPoint.x - tank.sprite.contentSize.width/2 - 5, worldPoint.y - tank.sprite.contentSize.width/2 - 5,
                                     tank.sprite.contentSize.width + 10, tank.sprite.contentSize.width + 10);
            
            // если квадрат танка и щуп пересекаются, то ...
            if (CGRectIntersectsRect(rect, [self createProbe:probe])) {
                
                // здесь мы хотим узнать, возможно, что танк человека между двумя танками компа
                // в таком случае, даже пересечение с щупом не отменяет выстрела
                // так как выстрел не долетит до друга, а взорвется на танке человека
                float distToPlayer = ccpDistance(self.position, [self.scene getChildByTag:player_tag].position);
                float distToFriend = ccpDistance(self.position, tank.position);
                
                if (distToFriend < distToPlayer)
                    isFriend = YES;
            }
        }
    }
    
    return isFriend;
}

-(void) rotateWithAngle:(float)angle moveAndCallBlock:(void(^)())block {

    // в этом методе мы вращаем танк на угол angle
    // возможно двигаем его к позиции от значений _dirX и dirY
    // и выполняем функционал, который пришел в блоке
    
    // говорим танку прекратить все движения (на всякий случай)
    [self stopAllActions];
    
    // находим разницу между углом своего танка и углом поворота (куда нажно поворачивать)
    // все нижние 3 строки нужны только для одной цели - определить время вращения
    // время = расстояние / скорость
    int differAngle = fabsf([self correctedRotation] - angle);
    if (differAngle == 270) differAngle = 90;
    float rotDuration = differAngle / rot_speed;
    
    // аналогично находим продолжительность (время) для движения танка, по той же формуле  t = d / s;
    float moveDuration = ccpDistance(self.position, ccp(_dirX, _dirY)) / move_speed;
    
    // вращаем танк
    id rot = [CCRotateTo actionWithDuration:rotDuration angle:angle];
    id cal = [CCCallBlock actionWithBlock:^{
        
        // после вращения
        
        // устанавливаем, что щупы не нащупали препятствия
        BOOL doesLeftProbeHit = NO;
        BOOL doesRightProbeHit = NO;
        
        // проходим по всем препятствиям, и если щупы пересекаются с ними, то включаем соответствующую булевую (левую или правую)
        for (CCSprite *wall in self.scene.wallsArray) {
            if (CGRectIntersectsRect([self.scene getRectFromSprite:wall], [self createProbe:JTProbeLeft])) doesLeftProbeHit = YES;
            if (CGRectIntersectsRect([self.scene getRectFromSprite:wall], [self createProbe:JTProbeRight])) doesRightProbeHit = YES;
        }
        
        // если ни один щуп не сработал, значит препятствия нет и можно ехать
        if (!doesLeftProbeHit && !doesRightProbeHit) {
            
            // и если X и Y будут отличатся от позиции своего танка, то будет движение
            // если не будет отличатся , то moveDuration будет равен 0 и движение будет мгновенным (симуляция отсутствия движения)
            // после чего вызовется блок, который мы передали при вызове метода
            
            // определяем anAction как действие движения
            id anAction = [CCMoveTo actionWithDuration:moveDuration position:ccp(_dirX, _dirY)];;
            
            // если впереди друг, то переопределяем anAction как действие ожидания
            // танк ждет (мы не будем создавать еще 1 очень сложный алгоритм объезда)
            if ([self isFriendAheadForProbe:JTProbeLeft] || [self isFriendAheadForProbe:JTProbeRight])
                anAction = [CCDelayTime actionWithDuration:3];
            
            // после движения (либо ожидания) выполнится блок, который пришел с вызовом функции
            id cal  = [CCCallBlock actionWithBlock:block];
                [self runAction:[CCSequence actions:anAction, cal, nil]];
            
        } else { // иначе сработал хоть 1 щуп
        
            // если сработал левый щуп , то стреляем с левого орудия
            // если правый, то - из правого
            if (doesLeftProbeHit)  [self shootFromX:-self.sprite.contentSize.width/2];
            if (doesRightProbeHit) [self shootFromX:self.sprite.contentSize.width/2];
            
            // после выстрела ждем некоторое время и разрешаем проверку
            id del = [CCDelayTime actionWithDuration:delay_after_shot];
            id cal = [CCCallBlock actionWithBlock:^{
                _doChoose = YES;
            }];
            [self runAction:[CCSequence actions:del, cal, nil]];
        }
    }];
    [self runAction:[CCSequence actions:rot, cal, nil]];
}

-(void) shootFromX:(float) x {

    // выстрел из разного Х, так как у нас 3 пушки: левая, правая и посередине
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:self.rotation], key_rotation,
                          [NSValue valueWithCGPoint:[self convertToWorldSpace:ccp(x, 15)]], key_position, nil];
    
    JTBullet *bullet = [[JTBullet alloc] initWithSprite:[CCSprite spriteWithFile:@"shot.png"] scene:self.scene properties:dict];
    [self.scene addChild:bullet z:15];
}

-(void) update:(float)dt {
    
    // Искуственный интеллект, танк врага будет ездить только под прямыми углами
    
    if (_doChoose) {
        
        // запрещаем проверку
        _doChoose = NO;
        
        // извлекаем из сцены указатель на танк игрока
        JTPlayerTank *playerTank = (JTPlayerTank*)[self.scene getChildByTag:player_tag];
        
        // находим разницу между позициями танков по X и по Y (она должна быть абсолютной, то есть не отрицательной)
        float differX = fabsf(self.position.x - playerTank.position.x);
        float differY = fabsf(self.position.y - playerTank.position.y);
        
        float angle = 0;
        
        // определяем, находится ли в зоне выстрела танк anAction
        BOOL inZoneY = differX < playerTank.sprite.contentSize.width/2;
        BOOL inZoneX = differY < playerTank.sprite.contentSize.width/2;
        
        // если в зоне выстрела, то ...
        if (inZoneX || inZoneY) {
            
            // если выстрел дотягивается до танка человека, то ехать не надо
            // позици движения присваиваем позицию себя
            if (ccpDistance(self.position, playerTank.position) <= _shotDistance) {
                _dirX = self.position.x;
                _dirY = self.position.y;
            }
            
            // если в танк игрока в зоне Y, то ...
            if (inZoneY) {
                // определяем выше или ниже танк игрока от себя. Если выше, то угол 0, если ниже, то 180
                angle = self.position.y < playerTank.position.y ? 0 : 180;
                
                // если в танк игрока в зоне X, то ...
            } else if (inZoneX) {
                // определяем слева или справа танк игрока от себя. Если слева, то угол 270, если справа, то 90
                angle = self.position.x < playerTank.position.x ? 90 : 270;
            }
            
            // вызываем метод вращения (и возможно движения), после чего выполнится блок
            [self rotateWithAngle:angle moveAndCallBlock:^{
               
                // если выстрел не дотягивается до танка человека, то нужно подъехать ближе
                // находим позицию движения
                if (ccpDistance(self.position, playerTank.position) > _shotDistance) {
                    
                    if (inZoneY) {
                    
                        int sign = self.position.y - playerTank.position.y < 0 ? 1 : -1;
                        
                        _dirX = self.position.x;
                        _dirY = playerTank.position.y - _shotDistance * 0.9 * sign;
                        
                    } else if (inZoneX) {
                    
                        int sign = self.position.x - playerTank.position.x < 0 ? 1 : -1;
                        
                        _dirY = self.position.y;
                        _dirX = playerTank.position.x - _shotDistance * 0.9 * sign;
                    }
                    
                    // разрешаем проверку
                    _doChoose = YES;
                    
                } else { // иначе выстрел дотягивается
                    
                    // выстрел
                    if (![self isFriendAheadForProbe:JTProbeCenter])
                        [self shootFromX:0];
                    
                    // после выстрела ждем некоторое время
                    id del = [CCDelayTime actionWithDuration:delay_after_shot];
                    id cal = [CCCallBlock actionWithBlock:^{
                        
                        // разрешаем проверку
                        _doChoose = YES;
                    }];
                    [self runAction:[CCSequence actions:del, cal, nil]];
                }
            }];
            
        } else { // если танк игрока не в зоне выстрела, то ...
            
            // если расстояние по вертикали между танками меньше чем расстояние по горизонтали, то вращаемся для движения по вертикали
            if (differY < differX) {
                
                // создаем координаты для движения танка
                _dirX = self.position.x;
                _dirY = playerTank.position.y;
                
                // определяем выше или ниже танк игрока от себя. Если выше, то угол 0, если ниже, то 180
                angle = self.position.y < playerTank.position.y ? 0 : 180;
         
            } else if (differY > differX) { // иначе вращаемся для движения по горизонтали
                
                // создаем координаты для движения танка
                _dirY = self.position.y;
                _dirX = playerTank.position.x;
                
                // определяем слева или справа танк игрока от себя. Если слева, то угол 270, если справа, то 90
                angle = self.position.x < playerTank.position.x ? 90 : 270;
            
            }
            
            // вызываем метод вращения и движения, после чего выполнится блок, в котором разрешаем проверку
            [self rotateWithAngle:angle moveAndCallBlock:^{
                _doChoose = YES;
            }];
        }
    }
}

@end
