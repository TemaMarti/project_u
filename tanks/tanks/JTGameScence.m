//
//  JTGameScence.m
//  tanks
//
//  Created by TemaMarti on 05.07.16.
//  Copyright 2016 TemaMarti. All rights reserved.
//

#import "JTGameScence.h"


@implementation JTGameScence

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
    JTGameScence *layer = [JTGameScence node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}

-(id) init {
    if (self = [super init]) {
        
    }
    
    return self;
}

@end
