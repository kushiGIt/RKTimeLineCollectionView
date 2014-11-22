//
//  RKGetTwitterTimeLine.h
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/10/26.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

typedef enum{
    RKGetTwiiterTimeLineErrorType_Success=0,
    RKGetTwiiterTimeLineErrorType_AccountError=1,
    RKGetTwiiterTimeLineErrorType_RequestError=2,
    RKGetTwiiterTimeLineErrorType_DataIsNull=3,
    RKGetTwiiterTimeLineErrorType_TwitterServerError=4
}RKGetTwitterTimeLineError;

@class RKGetTwitterTimeline;

@protocol RKGetTwitterDelegate;

typedef void (^CallbackHandlerForServer_TWITTER)(NSArray * resultArray, NSError *error, RKGetTwitterTimeLineError errorType);
typedef void (^CallbackHandlerForEdit_TWITTER)(NSArray*array, NSError *error);

@interface RKGetTwitterTimeline : NSObject

@property(nonatomic,weak)id<RKGetTwitterDelegate>delegate;
/**
 *  This method get a Twitter post from the server.  When the prosess is finished,run completion block.
 *
 *  @param parametersDic {NSDictionary}
 *  @param handler       {void}
 */
-(void)getTwitterTimelineFromServer:(NSDictionary*)parametersDic completion:(CallbackHandlerForServer_TWITTER)handler;
-(void)getFacebookTimelineNewlyWithCompletion:(CallbackHandlerForEdit_TWITTER)handler;
-(NSArray*)editTwitterTimeline:(NSArray*)responseArray;

@end
