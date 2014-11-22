//
//  RKGetTwitterTimeLine.m
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/10/26.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "RKGetTwitterTimeLine.h"

@implementation RKGetTwitterTimeline{
    
}
-(void)getFacebookTimelineNewlyWithCompletion:(CallbackHandlerForEdit_TWITTER)handler{
    
    NSUserDefaults*defaults=[NSUserDefaults standardUserDefaults];
    NSDictionary*parametersDic;
    
    if ([defaults stringForKey:@"TWITTER_SINCE_ID"].length==0) {
        
        parametersDic=@{@"include_entities": @"1",@"count": @"200"};
        NSLog(@"request parameters don't have since_id");
        
    }else{
        
        parametersDic=@{@"include_entities": @"1",@"count": @"200",@"since_id": [defaults stringForKey:@"TWITTER_SINCE_ID"]};
        NSLog(@"request parameters have since_id");
        
    }

    [self getTwitterTimelineFromServer:parametersDic completion:^(NSArray*resultsArray,NSError*getTimelineFromServerError,RKGetTwitterTimeLineError errorType){
        
        switch (errorType) {
            case RKGetTwiiterTimeLineErrorType_Success:
                
                if (handler) {
                    handler([self editTwitterTimeline:resultsArray],getTimelineFromServerError);
                }
                break;
                
            default:
                
                if (handler) {
                    handler([[NSArray alloc]init],getTimelineFromServerError);
                }
                break;
        
        }
        
    }];
    
}

-(NSArray*)editTwitterTimeline:(NSArray*)responseArray{
    
    NSMutableArray*array=[[NSMutableArray alloc]init];
    
    dispatch_group_t group = dispatch_group_create();
 
    for (NSDictionary *tweet in responseArray) {
    
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_group_async(group, queue, ^{
            
            NSLock*myLock;
            [myLock lock];
            
            @try {
                
                NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                
                NSString*twitterTextStr=[NSString stringWithFormat:@"%@",[tweet objectForKey:@"text"]];
                [dic setObject:twitterTextStr forKey:@"TEXT"];
                
                NSDictionary *user = tweet[@"user"];
                [dic setObject:user[@"screen_name"] forKey:@"USER_NAME"];
                [dic setObject:user[@"profile_image_url"] forKey:@"USER_ICON"];
                
                //TwiietrDate→NSDate Convert
                NSDateFormatter* inFormat = [[NSDateFormatter alloc] init];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                [inFormat setLocale:locale];
                [inFormat setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
                NSString*original_Twitter_Date=[NSString stringWithFormat:@"%@",tweet[@"created_at"]];
                NSDate *date =[inFormat dateFromString:original_Twitter_Date];
                
                [dic setObject:date forKey:@"POST_DATE"];
                
                [dic setObject:@"TWITTER" forKey:@"TYPE"];
                [array addObject:dic];
            
            }
            @finally {
                
                [myLock unlock];
            
            }
        
        });
        
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return array;
    
}
-(void)getTwitterTimelineFromServer:(NSDictionary*)parametersDic completion:(CallbackHandlerForServer_TWITTER)handler{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted,NSError *accountsError){
            
            if (granted==YES) {
                
                NSArray*accounts=[accountStore accountsWithAccountType:accountType];
                
                if (accounts!=nil&&accounts.count!=0) {
                    
                    ACAccount *twAccount = accounts[0];
                    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                    request.account = twAccount;
                    
                    [request performRequestWithHandler:^(NSData*responseData,NSHTTPURLResponse*urlResponse,NSError*error){
                        
                        if (error) {
                            
                            NSLog(@"twitter request...Failured");
                            
                            if (handler) {
                                handler(nil,error,RKGetTwiiterTimeLineErrorType_TwitterServerError);
                            }
                        
                        }else{
                            
                            if (urlResponse) {
                                NSError *jsonError;
                                NSLog(@"Completion of receiving Twitter timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                                
                                NSMutableArray*responseArray=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                                
                                if (jsonError) {
                                    
                                    NSLog(@"%s,%@",__func__,jsonError);
                                    
                                }else{
                                    
                                    if (![[[[responseArray valueForKey:@"errors"]valueForKey:@"messege"]firstObject]isEqual:[NSNull null]]) {
                                        
                                        NSLog(@"twitter request...Failured");
                                        NSString*errorCode=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"code"][0]];
                                        NSString*errorMessege=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"message"][0]];
                                        NSLog(@"%@",errorCode);
                                        NSLog(@"%@",errorMessege);
                                        
                                        NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                        [errDetails setValue:errorMessege forKey:NSLocalizedDescriptionKey];
                                        NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:[errorCode integerValue] userInfo:errDetails];
                                        
                                        if (handler) {
                                            handler(nil,twitterError,RKGetTwiiterTimeLineErrorType_TwitterServerError);
                                        }
                                        
                                    }else{
                                        
                                        if (responseArray.count==0) {
                                            
                                            NSLog(@"There is no new data.");
                                            
                                            NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                            [errDetails setValue:@"There is no new data." forKey:NSLocalizedDescriptionKey];
                                            NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:100 userInfo:errDetails];
                                            
                                            if (handler) {
                                                handler(nil,twitterError,RKGetTwiiterTimeLineErrorType_DataIsNull);
                                            }
                                            
                                        }else{
                                            
                                            if (handler) {
                                                handler(responseArray,nil,RKGetTwiiterTimeLineErrorType_Success);
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }else{
                                
                                NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                [errDetails setValue:@"There was no response from the server." forKey:NSLocalizedDescriptionKey];
                                NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:101 userInfo:errDetails];
                                
                                if (handler) {
                                    handler(nil,twitterError,RKGetTwiiterTimeLineErrorType_RequestError);
                                }
                                
                            }
                            
                        }
                        
                    }];
                    
                    
                }else{
                    
                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                    [errDetails setValue:@"App does not have a valid Twitter account." forKey:NSLocalizedDescriptionKey];
                    NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:102 userInfo:errDetails];
                    
                    if (handler) {
                        handler(nil,twitterError,RKGetTwiiterTimeLineErrorType_AccountError);
                    }
                    
                }
                
            }else{
                
                NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                [errDetails setValue:@"The user did not accept the permission of the account of app." forKey:NSLocalizedDescriptionKey];
                NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:103 userInfo:errDetails];
                
                if (handler) {
                    handler(nil,twitterError,RKGetTwiiterTimeLineErrorType_AccountError);
                }
                
            }
        
    }];


}

@end
