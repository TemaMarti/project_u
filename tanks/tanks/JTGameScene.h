//
//  JTGameScence.h
//  tanks
//
//  Created by TemaMarti on 05.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define key_position @"key_position"
#define key_rotation @"key_rotation"
#define key_shot_distance @"key_shot_distance"

#define player_tag 12347 //по этому tag, enemyTank будет находить playerTank

@interface JTGameScene : CCLayer {
    
}

// передача в isDoing
@property(nonatomic, assign) BOOL isMovingForward;
@property(nonatomic, assign) BOOL isMovingBack;
@property(nonatomic, assign) BOOL isRotatingLeft;
@property(nonatomic, assign) BOOL isRotatingRight;
@property(nonatomic, strong) NSMutableArray *wallsArray;
@property(nonatomic, strong) NSMutableArray *enemiesArray;

+(CCScene *) scene;

-(CGRect) getRectFromSprite:(CCSprite*)sprt;

@end

