//
//  JTBullet.m
//  tanks
//
//  Created by TemaMarti on 10.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import "JTBullet.h"
#import "JTGameScene.h"
#import "SimpleAudioEngine.h"


@implementation JTBullet

-(void) animateExplosion {
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"Explosion1.mp3"];
    
    //анимация.......
    //массив кадров анимации
    NSMutableArray *animFrames = [NSMutableArray array];
    
    //заполнение массива из 15 кадров
    for (int i = 1; i < 16; i++) {
        
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"expl_%d.png", i]];
        [animFrames addObject:frame];
    }
    
    //спрайт первого кадра
    CCSprite *expl = [CCSprite spriteWithSpriteFrameName:@"expl_1.png"];
    expl.position = self.position;
    expl.scale = 2;
    [self.scene addChild:expl z:20];
    
    CCAnimation *animation = [CCAnimation animationWithSpriteFrames:animFrames delay:0.05]; //создаем анимацию из массива кадров
    
    //запуск....уничтожение
    id anim = [CCAnimate actionWithAnimation:animation];
    id cal = [CCCallBlock actionWithBlock:^{
        
        [expl removeFromParentAndCleanup:YES];
    }];
    
    [expl runAction:[CCSequence actions:anim, cal, nil]];
}

-(id) initWithSprite:(CCSprite *)sprt scene:(JTGameScene *)scene properties:(NSDictionary *)props {
    
    if (self = [super initWithSprite:sprt scene:scene properties:props]) {
        
        [[SimpleAudioEngine sharedEngine] playEffect:@"shot.wav"];
        
        // расстояние которое преодолевает снаряд 500 pix
        _distance = 250;
        
        self.rotation = [[props objectForKey:key_rotation] floatValue];
        self.position = [[props objectForKey:key_position] CGPointValue];
        
        //движение выстрела......
        //.......................
        float rad = self.rotation * (M_PI/180);
        
        //цель выстрела
        CGPoint aimPos = ccpAdd(self.position, ccp(sin(rad) * _distance, cos(rad) * _distance));
        
        //движение к определенной точке
        id mov = [CCMoveTo actionWithDuration:1.5 position:aimPos];
        
        //удаление пули из сцены
        id cal = [CCCallBlock actionWithBlock:^{
            
            [self animateExplosion];
            [self removeFromParentAndCleanup:YES]; //полная очистка всех экшенов, которые выполнялись
        }];
        [self runAction:[CCSequence actions:mov, cal, nil]];//выполнение нового экшена
    }
    
    return self;
}

-(void) update:(float)dt{
    
    //на протяжении всего полета пули проверяется наличие стены
    //создаем массив для уничтожения стен
    NSMutableArray *deleteArray = [NSMutableArray array];
    
    //извлекаются в цикл поочередно все стены
    for (CCSprite *wall in self.scene.wallsArray) {
        
        //если прямоугольник стены содержит пулю то
        if (CGRectContainsPoint([self.scene getRectFromSprite:wall], self.position)) {
            
            [deleteArray addObject:wall];           //в массив уничтожения добовляем стену
            [wall removeFromParentAndCleanup:YES];  //удалеям стену из сцены
            [self animateExplosion];                //анимируем взрыв
            [self removeFromParentAndCleanup:YES];  //сращу же после столкновения удалем пулю из сцены
        }
    }
    
    //очистка массива стен
    for (CCSprite *wall in deleteArray) {
        
        [self.scene.wallsArray removeObject:wall];
    }
    
    [deleteArray removeAllObjects]; //очистка массива
}

@end















