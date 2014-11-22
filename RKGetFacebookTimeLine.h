//
//  RKGetFacebookTimeLine.h
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/10/25.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
typedef NS_ENUM(NSUInteger,RKGetFacebookTimeLineError){
    /**
     *  Return when there was no error and app was able to obtain the facebook information correctly.
     */
    RKGetFacebookTimeLineErrorType_Success=0,
    /**
     *  Return when app does not have a valid facebook account.
     */
    RKGetFacebookTimeLineErrorType_AccountIsNULL=1,
    /**
     *  Return when the user did not accept the permission of the account of app.
     */
    RKGetFacebookTimeLineErrorType_NoPermission=2,
    /**
     *  Return when there was no response from the server.
     */
    RKGetFacebookTimeLineErrorType_RequestError=3,
    /**
     *  Return when there was no new data on facebook server.
     */
    RKGetFacebookTimeLineErrorType_DataIsNull=4,
    /**
     *  Return when there was error of facebook server or miss of the developer's code.
     */
    RKGetFacebookTimeLineErrorType_FacebookServerError=5
};



@class RKGetFacebookTimeLine;

@protocol RKGetFacebookDelegate;

typedef void (^CallbackHandlerForServer_FACEBOOK)(NSArray *resultArray, NSError *error, RKGetFacebookTimeLineError errorType);
typedef void (^CallbackHandlerForEdit_FACEBOOK)(NSArray*array, NSError *error);

@interface RKGetFacebookTimeLine : NSObject{
    
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;

@property(nonatomic,weak)id<RKGetFacebookDelegate>delegate;
/**
 *  This method get a facebook post from the server.  When the prosess is finished,run completion block.
 *
 *  @param permissionDic You must set facebook permission.
 *  @param handler       NSArray *resultArray, NSError *error, RKGetFacebookTimeLineError errorType
 */
-(void)getFacebookTimelineFromServer:(NSDictionary*)permissionDic completion:(CallbackHandlerForServer_FACEBOOK)handler;
/**
 *  This methods get data that edited the data that was retrieved from the server.When the prosess is finished,run completion block.
 *
 *  @param NSDictionary *resultsDic, NSError *error
 */
-(void)getFacebookTimelineNewlyWithCompletion:(CallbackHandlerForEdit_FACEBOOK)handler;
/**
 *  Return edited facebook post.  When the prosess is finished,run completion block
 *
 *  @param newsfeed You must get data from server.
 *
 *  @return LIKE_DATA,PICTURE_DATA,POST_DATE,TEXT,TYPE,USER_ID,USER_NAME in NSDictonary.
 */

-(NSArray*)editFacebookTimeline:(NSArray*)newsfeed;

@end
