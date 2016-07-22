//
//  JTObject.h
//  tanks
//
//  Created by TemaMarti on 09.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

//класс для игровых объектов
@class JTGameScene;

@interface JTObject : CCNode {
    
}

@property(nonatomic, strong) CCSprite *sprite;
@property(nonatomic, strong) JTGameScene *scene;
@property(nonatomic, assign) CGSize winSize;

//свойства объектов
-(id) initWithSprite:(CCSprite*)sprt scene:(JTGameScene*)scene properties:(NSDictionary*)props;
-(void) update:(float)dt;

@end
