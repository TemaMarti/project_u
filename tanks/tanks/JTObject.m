//
//  JTObject.m
//  tanks
//
//  Created by TemaMarti on 09.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import "JTObject.h"


@implementation JTObject

-(id) initWithSprite:(CCSprite*)sprt scene:(JTGameScene*)scene properties:(NSDictionary*)props {
    
    if (self = [super init]) {
        
        _winSize = [CCDirector sharedDirector].winSize;
        _scene = scene;
        _sprite = sprt;
        [self addChild:sprt];
        
        //указатель на метод
        [self schedule:@selector(update:)];
        
    }
    
    return self;
}

-(void) update:(float)dt {
    
}

@end
