//
//  GetAllTimeLine.m
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/11/16.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "GetAllTimeLine.h"

@implementation GetAllTimeLine
+(void)getAllTimeLine:(CallbackHandlerForGetInfo)handler{
    
    NSLock*threadLock=[[NSLock alloc]init];
    
    __block int isProgress=0;
    __block NSMutableArray*urlStrArray=[[NSMutableArray alloc]init];
    __block NSMutableArray*dataArray=[[NSMutableArray alloc]init];
    
    RKGetFacebookTimeLine*test_facebook=[[RKGetFacebookTimeLine alloc]init];
    [test_facebook getFacebookTimelineNewlyWithCompletion:^(NSArray*array,NSError*error){
        
        [dataArray addObjectsFromArray:array];
        
        dispatch_group_t group_facebook = dispatch_group_create();
        
        for (NSDictionary*dataDic in array) {
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_group_async(group_facebook, queue, ^{
                
                [threadLock lock];
                
                @try {
                    
                    NSString*urlStr=[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",[dataDic objectForKey:@"USER_ID"]];
                    [urlStrArray addObject:urlStr];
                    
                }
                
                @finally {
                    
                    [threadLock unlock];
                    
                }
                
            });
            
        }
        
        dispatch_group_wait(group_facebook, DISPATCH_TIME_FOREVER);
        
        NSLog(@"facebook task...done");
        
        isProgress++;
    }];
    
    RKGetTwitterTimeline*test_twitter=[[RKGetTwitterTimeline alloc]init];
    [test_twitter getFacebookTimelineNewlyWithCompletion:^(NSArray*array,NSError*error){
        
        [dataArray addObjectsFromArray:array];
        
        dispatch_group_t group_twitter = dispatch_group_create();
        
        for (NSDictionary*dataDic in array) {
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_group_async(group_twitter, queue, ^{
                
                [threadLock lock];
                
                @try {
                    
                    NSString*urlStr=[NSString stringWithFormat:@"%@",[dataDic objectForKey:@"USER_ICON"]];
                    [urlStrArray addObject:urlStr];
                    
                }
                @finally {
                    
                    [threadLock unlock];
                    
                }
                
            });
            
        }
        
        dispatch_group_wait(group_twitter, DISPATCH_TIME_FOREVER);
        
        NSLog(@"twitter task...done");
        
        isProgress++;
    }];
    
    
    while(isProgress<2){
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]];
    }
    
    NSLog(@"Process for receiving the data has been completed all.");
    
    if (handler) {
        
        handler(urlStrArray,dataArray);
    
    }
}
@end
