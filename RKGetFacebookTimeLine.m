//
//  RKGetFacebookTimeLine.m
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/10/25.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "RKGetFacebookTimeLine.h"

@implementation RKGetFacebookTimeLine{
    
}
-(void)getFacebookTimelineNewlyWithCompletion:(CallbackHandlerForEdit_FACEBOOK)handler{
    
    
    NSDictionary*permissionDic=@{ACFacebookAppIdKey : @"878372405515997",ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,ACFacebookPermissionsKey : @[@"email",@"read_stream"]};
    
    [self getFacebookTimelineFromServer:permissionDic completion:^(NSArray*resultsArray,NSError*getTimelineFromServerError,RKGetFacebookTimeLineError errorType){
        
        switch (errorType) {
            
            case RKGetFacebookTimeLineErrorType_Success:{
                
                if (handler) {
                    handler([self editFacebookTimeline:resultsArray],getTimelineFromServerError);
                }
                
                break;
                
            }default:{
                
                if (handler) {
                    handler([[NSArray alloc]init],getTimelineFromServerError);
                }
                
                break;
                
            }
        
        }
        
    }];

}
-(NSArray*)editFacebookTimeline:(NSArray*)newsfeed{
    
    
    NSMutableArray*array=[[NSMutableArray alloc]init];
    NSLock*lock;
    
    dispatch_group_t group = dispatch_group_create();
    
    for (int i=0; i<[newsfeed count];i++) {
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(group, queue, ^{
            
            [lock lock];
            
            @try {
                
                NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                
                //user name
                [dic setObject:[[newsfeed valueForKey:@"from"]valueForKey:@"name"][i] forKey:@"USER_NAME"];
                //user id
                [dic setObject:[[newsfeed valueForKey:@"from"]valueForKey:@"id"][i] forKey:@"USER_ID"];
                
                //text data
                [dic setObject:[newsfeed valueForKey:@"message"][i] forKey:@"TEXT"];
                
                //date data
                NSString*Original_ISO_8601_Date=[NSString stringWithFormat:@"%@",[newsfeed valueForKey:@"created_time"][i]];
                NSDate* date_converted;
                NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                date_converted = [formatter dateFromString:Original_ISO_8601_Date];
                [dic setObject:date_converted forKey:@"POST_DATE"];
                
                //like data
                if ([[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:[NSNull null] forKey:@"LIKE_DATA"];
                    
                }else{
                    
                    [dic setObject:[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] forKey:@"LIKE_DATA"];
                    
                }
                
                //newsfeed picture
                if ([[newsfeed valueForKey:@"picture"]isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:[NSNull null] forKey:@"PICTURE_DATA"];
                    
                }else{
                    
                    [dic setObject:[[newsfeed valueForKey:@"picture"]objectAtIndex:i] forKey:@"PICTURE_DATA"];
                    
                }
                
                
                //set type Ex.)facebook,twitter
                [dic setObject:@"FACEBOOK" forKey:@"TYPE"];
                
                [array addObject:dic];
                
            }
            @finally {
                
                [lock unlock];
            
            }
            
        });
        
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return array;
}
-(void)getFacebookTimelineFromServer:(NSDictionary*)permissionDic completion:(CallbackHandlerForServer_FACEBOOK)handler{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    [accountStore requestAccessToAccountsWithType:accountType options:permissionDic completion:^(BOOL granted, NSError *accountsError){
        
        if (granted==YES) {
            
            NSArray *facebookAccounts = [accountStore accountsWithAccountType:accountType];
            
            if (facebookAccounts!=nil&&facebookAccounts.count!=0) {
                
                ACAccount *facebookAccount = [facebookAccounts lastObject];
                
                ACAccountCredential *facebookCredential = [facebookAccount credential];
                NSString *accessToken = [facebookCredential oauthToken];
                
                NSURL*url=[NSURL URLWithString:@"https://graph.facebook.com/me/home"];
                NSDictionary*parametersDic=[[NSDictionary alloc]initWithObjectsAndKeys:accessToken,@"access_token",@1000,@"limit", nil];
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                request.account = facebookAccount;
                
                [request performRequestWithHandler:^(NSData*responseData,NSHTTPURLResponse*urlResponse,NSError*error){
                    
                    
                        if (error) {
                            NSLog(@"Facebook error==>%@",error);
                        }
                        
                        if (urlResponse) {
                            
                            NSError *jsonError;
                            NSLog(@"Completion of receiving Facebook timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                            
                            NSArray*responseArray=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                            
                            if (jsonError) {
                                
                                NSLog(@"%s,%@",__func__,jsonError);
                                
                            }else{
                                
                                if ([[responseArray valueForKey:@"error"]valueForKey:@"message"]) {
                                    
                                    NSDictionary*facebookErrorDic=[[NSDictionary alloc]initWithDictionary:[responseArray valueForKey:@"error"]];
                                    
                                    NSString*errorCode=[NSString stringWithFormat:@"%@",[facebookErrorDic objectForKey:@"code"]];
                                    NSString*errorMessege=[NSString stringWithFormat:@"%@",[facebookErrorDic objectForKey:@"message"]];
                                    
                                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                    [errDetails setValue:errorMessege forKey:NSLocalizedDescriptionKey];
                                    
                                    NSError*resultsError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:[errorCode integerValue] userInfo:errDetails];
                                    
                                    if (handler) {
                                        handler(nil,resultsError,RKGetFacebookTimeLineErrorType_FacebookServerError);
                                    }
                                    
                                }else{
                                    
                                    if ([[responseArray valueForKey:@"data"]count]==0) {
                                        
                                        NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                        [errDetails setValue:@"There is no new data." forKey:NSLocalizedDescriptionKey];
                                        NSError*resultsError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:200 userInfo:errDetails];
                                        
                                        if (handler) {
                                            handler(nil,resultsError,RKGetFacebookTimeLineErrorType_DataIsNull);
                                        }
                                        
                                    }else{
                                        
                                        if (handler) {
                                            handler([responseArray valueForKey:@"data"],nil,RKGetFacebookTimeLineErrorType_Success);
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                            
                        }else{
                            
                            NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                            [errDetails setValue:@"There was no response from the server." forKey:NSLocalizedDescriptionKey];
                            NSError*resultsError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:201 userInfo:errDetails];
                            
                            if (handler) {
                                handler(nil,resultsError,RKGetFacebookTimeLineErrorType_RequestError);
                            }
                            
                        }
                
                }];
                
            }else{
                
                NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                [errDetails setValue:@"App does not have a valid facebook account." forKey:NSLocalizedDescriptionKey];
                NSError*resultsError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:202 userInfo:errDetails];
                
                if (handler) {
                    handler(nil,resultsError,RKGetFacebookTimeLineErrorType_AccountIsNULL);
                }
                
            }
        
        }else{
            
            NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
            [errDetails setValue:@"The user did not accept the permission of the account of app." forKey:NSLocalizedDescriptionKey];
            NSError*resultsError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:203 userInfo:errDetails];
            
            if (handler) {
                handler(nil,resultsError,RKGetFacebookTimeLineErrorType_NoPermission);
            }
        }
        
    }];
}
@end
