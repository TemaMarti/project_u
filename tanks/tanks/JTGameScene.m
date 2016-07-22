//
//  JTGameScence.m
//  tanks
//
//  Created by TemaMarti on 05.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import "JTGameScene.h"
#import "JTPlayerTank.h"
#import "SimpleAudioEngine.h"
#import "JTEnemyTank.h"

#define pressed_tag 1234

//Создание категории интерфейса
@interface JTGameScene()
@property(nonatomic, strong) JTPlayerTank *playerTank;
@property(nonatomic, assign) CGSize winSize;

//кнопки движения и атаки
@property(nonatomic, strong) CCSprite *rotLeft;
@property(nonatomic, strong) CCSprite *rotRight;
@property(nonatomic, strong) CCSprite *moveForvard;
@property(nonatomic, strong) CCSprite *moveBack;
@property(nonatomic, strong) CCSprite *attack;
@property(nonatomic, assign) ALuint engineSound;

@end

@interface JTGameScene (Private)

-(CCSprite*) buttonWithName:(NSString*)name pressedName:(NSString*)pressedName pos:(CGPoint)pos flipX:(BOOL)flipX flipY:(BOOL)flipY;

-(void) createEnemyWithPosition:(CGPoint)pos;

@end

@implementation JTGameScene

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
    JTGameScene *layer = [JTGameScene node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}


# pragma mark - INIT -

-(id) init {
    
    if (self = [super init]) {
        
        //[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"real_war.mp3" loop:YES];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Explosion.plist"];
        
        _wallsArray = [[NSMutableArray alloc] init];
        
        _enemiesArray = [[NSMutableArray alloc] init];
        
        self.winSize = [CCDirector sharedDirector].winSize; // размер экрана
        
        // цветовой слой
        CCLayerColor *lc = [CCLayerColor layerWithColor:ccc4(20, 35, 20, 255)];
        [self addChild:lc];
        
        //словарь из содержимого файла Level_1.plist
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Level_1" ofType:@"plist"]];
        
        //извлекаем массив наших стен
        NSArray *array = [dict objectForKey:@"Walls"];
        
        //извлечение наших string из plist'a
        for (NSDictionary *wallDict in array){
            
            //создание самой стены
            CCSprite *wall = [CCSprite spriteWithFile:@"brickWall.png"];
            wall.position = ccp([[wallDict objectForKey:@"x"] floatValue], [[wallDict objectForKey:@"y"] floatValue]);
            [self addChild:wall];
            
            [_wallsArray addObject:wall];
        }
        
        //создаем наш танк
        _playerTank = [[JTPlayerTank alloc] initWithSprite:[CCSprite spriteWithFile:@"Tank1.png"] scene:self properties:nil];
        _playerTank.position = ccp(_winSize.width/2, _winSize.height/2);
        [self addChild:_playerTank z:50 tag:player_tag];
        
        [self createEnemyWithPosition:ccp(350, 200)];
        
        //кнопки атаки и передвежений (их файл, позиция)
        _rotLeft = [self buttonWithName:@"btnRotate.png" pressedName:@"btnRotatePressed.png" pos:ccp(20, 80) flipX:YES flipY:NO];
        _rotRight = [self buttonWithName:@"btnRotate.png" pressedName:@"btnRotatePressed.png" pos:ccp(60, 80) flipX:NO flipY:NO];
        _moveForvard = [self buttonWithName:@"btnArrow.png" pressedName:@"btnArrowPressed.png" pos:ccp(40.5, 110) flipX:NO flipY:NO];
        _moveBack = [self buttonWithName:@"btnArrow.png" pressedName:@"btnArrowPressed.png" pos:ccp(40.5, 50) flipX:NO flipY:YES];
        _attack = [self buttonWithName:@"btnFire.png" pressedName:@"btnFirePressed.png" pos:ccp(_winSize.width - 30, 80) flipX:NO flipY:NO];
        
        self.touchEnabled = YES;
    }
    
    return self;
}


#pragma mark - PRIVATE_METHODS -


//создание вражеского танка
-(void) createEnemyWithPosition:(CGPoint)pos {
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:pos], key_position,
                          [NSNumber numberWithFloat:300], key_shot_distance, nil];
    JTEnemyTank *tank = [[JTEnemyTank alloc] initWithSprite:[CCSprite spriteWithFile:@"Tank2.png"] scene:self properties:dict];
    tank.rotation = 0;
    [self addChild:tank z:15];
    
    [_enemiesArray addObject:tank];
}

// функция расположения спрайтов движения в прямоугольнике
-(CGRect) getRectFromSprite:(CCSprite*)sprt {
    return CGRectMake(sprt.position.x - sprt.contentSize.width/2 ,
                      sprt.position.y - sprt.contentSize.height/2,
                      sprt.contentSize.width, sprt.contentSize.height);
}

-(CCSprite*) buttonWithName:(NSString*)name pressedName:(NSString*)pressedName pos:(CGPoint)pos flipX:(BOOL)flipX flipY:(BOOL)flipY {
    
    //создание спрайта и размещение по позиции
    CCSprite *sprt = [CCSprite spriteWithFile:name];
    sprt.position = pos;
    sprt.flipX = flipX;
    sprt.flipY = flipY;
    [self addChild:sprt z:100];
    
    CCSprite *pressed = [CCSprite spriteWithFile:pressedName];
    pressed.flipX = flipX;
    pressed.flipY = flipY;
    pressed.anchorPoint = ccp(0, 0);
    pressed.tag = pressed_tag;
    pressed.visible = NO;
    [sprt addChild:pressed];
    
    return sprt;
}

-(void) checkForActionInBegining:(CCSprite*)sprt isDoing:(BOOL*)isDoing location:(CGPoint)location {
    
    //соприкосновения находятся в пределах данного спрайта
    if (CGRectContainsPoint([self getRectFromSprite:sprt], location)) {
        
        CCNode *pressed = [sprt getChildByTag:pressed_tag]; //видимость
        pressed.visible = YES;
        *isDoing = YES;
        
        _engineSound = [[SimpleAudioEngine sharedEngine] playEffect:@"engine.wav"];
    }
    
}

-(void) checkForActionInEnding:(CCSprite*)sprt isDoing:(BOOL*)isDoing location:(CGPoint)location {
        
        //соприкосновения находятся в пределах данного спрайта
    if (CGRectContainsPoint([self getRectFromSprite:sprt], location)) {
            
        CCNode *pressed = [sprt getChildByTag:pressed_tag]; //видимость
        pressed.visible = NO;
        *isDoing = NO;
        
        [[SimpleAudioEngine sharedEngine] stopEffect:_engineSound];
    }
}


#pragma mark - TOUCHES -

//работа с соприкосновениями
-(void) registerWithTouchDispatcher {
    
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority swallowsTouches:NO];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    
   // Возвращение точки соприкосновения
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    
    //NSLog(@"ok");
    //NSLog(@"ccTouchBegan");
    //передача указателей
    [self checkForActionInBegining:_rotLeft isDoing:&_isRotatingLeft location:location];
    [self checkForActionInBegining:_rotRight isDoing:&_isRotatingRight location:location];
    [self checkForActionInBegining:_moveForvard isDoing:&_isMovingForward location:location];
    [self checkForActionInBegining:_moveBack isDoing:&_isMovingBack location:location];
    
    if (CGRectContainsPoint([self getRectFromSprite:_attack], location)) {
        
        CCNode *pressed = [_attack getChildByTag:pressed_tag]; //видимость
        pressed.visible = YES;
        
        // при нажатии attack произойдет выстрел
        [_playerTank shoot];
    }
    
    return YES;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    
    //при разжатии возвращем предыдущий спрайт
    
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    //передача указателей
    [self checkForActionInEnding:_rotLeft isDoing:&_isRotatingLeft location:location];
    [self checkForActionInEnding:_rotRight isDoing:&_isRotatingRight location:location];
    [self checkForActionInEnding:_moveForvard isDoing:&_isMovingForward location:location];
    [self checkForActionInEnding:_moveBack isDoing:&_isMovingBack location:location];
   
    if (CGRectContainsPoint([self getRectFromSprite:_attack], location)) {
        
        CCNode *pressed = [_attack getChildByTag:pressed_tag]; //видимость
        pressed.visible = NO;
    }
    
}

@end
