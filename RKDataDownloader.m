//
//  RKDataDownloader.m
//  RKDataDownloader
//
//  Created by RyousukeKushihata on 2014/11/01.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "RKDataDownloader.h"


@interface RKDataDownloader()

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSURLSessionDownloadTask *sessionTask;

@property (nonatomic) NSMutableDictionary*taskDataDic;

@property (nonatomic) double taskCount;

@property (nonatomic) int completeTaskCount;

@property (nonatomic) NSMutableDictionary*complrteDataDic;

@property (nonatomic) NSMutableDictionary*completeDataErrorDic;

@property (nonatomic) BOOL isNeedDownload;

@property BOOL isInitWithArray;

@end

@implementation RKDataDownloader{
    NSCache*dataCashe;
}

-(id)initWithUrlArray_background:(NSArray*)urlArray{
    
    dispatch_semaphore_t semaphone =dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        self.isInitWithArray=YES;
        
        if (self==[super init]) {
            
            if (urlArray.count==0) {
                
                self.isNeedDownload=NO;
                
            }else{
                
                self.taskDataDic=[[NSMutableDictionary alloc]init];
                self.completeDataErrorDic=[[NSMutableDictionary alloc]init];
                self.complrteDataDic=[[NSMutableDictionary alloc]init];
                
                for (NSString*sorceURL in [self encodeUrlFromJapaneseUrl:urlArray]) {
                    
                    [self.taskDataDic setObject:[NSNumber numberWithDouble:0.0] forKey:sorceURL];
                    
                }
                
                self.taskCount=(double)self.taskDataDic.count;
                
                NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.RKDownloader"];
                sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
                
                self.session=[NSURLSession sessionWithConfiguration:sessionConfiguration delegate:(id)self delegateQueue:nil];
                
                self.completeTaskCount=0;
                
                self.isNeedDownload=YES;
                
            }
            
        }
        
        dispatch_semaphore_signal(semaphone);
        
    });
    
    dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
    
    return self;
}
-(id)initWithUrlArray_defaults:(NSArray *)urlArray{
    
    self.isInitWithArray=YES;
    
    dispatch_semaphore_t semaphone =dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        if (self==[super init]) {
            
            if (urlArray.count==0) {
                
                self.isNeedDownload=NO;
                
            }else{
                
                self.taskDataDic=[[NSMutableDictionary alloc]init];
                self.completeDataErrorDic=[[NSMutableDictionary alloc]init];
                self.complrteDataDic=[[NSMutableDictionary alloc]init];
                
                for (NSString*sorceURL in [self encodeUrlFromJapaneseUrl:urlArray]) {
                    
                    [self.taskDataDic setObject:[NSNumber numberWithDouble:0.0] forKey:sorceURL];
                    
                }
                
                self.taskCount=(double)self.taskDataDic.count;
                
                NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
                sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
                
                self.session=[NSURLSession sessionWithConfiguration:sessionConfiguration delegate:(id)self delegateQueue:nil];
                
                self.completeTaskCount=0;
                
                self.isNeedDownload=YES;
                
            }
            
        }
        
        dispatch_semaphore_signal(semaphone);
        
    });
    
    dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
    
    return self;
    
}
-(void)startDownloads{
    
    if (self.isInitWithArray==YES) {
        
        if (self.isNeedDownload==NO) {
            
            if (self.completeTaskCount==self.taskCount) {
                
                [self.delegate didFinishAllDownloadsWithDataDictinary:NULL withErrorDic:NULL];
                
            }
            
        }else{
            
            for (int i=0; i<[self.taskDataDic.allKeys count]; i++) {
                
                self.sessionTask = [self.session downloadTaskWithURL:[NSURL URLWithString:self.taskDataDic.allKeys[i]]];
                [self.sessionTask resume];
                
            }
            
            self.isInitWithArray=NO;
            
        }
        
    }else{
        
        [[NSException exceptionWithName:@"RKDownloader init exception" reason:@"you must use -(void)initWithArray: first. You musu not use -(id)init." userInfo:nil]raise];
        
    }
    
    
}
#pragma mark - NSURLSession Delegate method implementation
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    if ([self.delegate respondsToSelector:@selector(didFinishDownloadData:withError:dataWithUrl:)] || [self.delegate respondsToSelector:@selector(didFinishAllDownloadsWithDataDictinary:withErrorDic:)]) {
        
        __block NSError*readingDataError;
        __block NSData*downloededData;
        __block NSString*urlStr=[NSString stringWithFormat:@"%@",[[downloadTask originalRequest]URL]];
        
        dispatch_semaphore_t semaphone =dispatch_semaphore_create(0);
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            
            downloededData=[NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&readingDataError];
            
            if (downloededData.length==0) {
                
                [self.complrteDataDic setObject:[NSNull null] forKey:urlStr];
                
            }else{
                
                [self.complrteDataDic setObject:downloededData forKey:urlStr];
                
            }
            
            if (readingDataError==nil) {
                
                [self.completeDataErrorDic setObject:[NSNull null] forKey:urlStr];
                
            }else{
                
                [self.completeDataErrorDic setObject:readingDataError forKey:urlStr];
                
            }
            
            dispatch_semaphore_signal(semaphone);
            
        });
        dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
        
        if ([self.delegate respondsToSelector:@selector(didFinishDownloadData:withError:dataWithUrl:)]) {
            
            [self.delegate didFinishDownloadData:downloededData withError:readingDataError dataWithUrl:urlStr];
            
        }
        
    }
    
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if (error != nil) {
        
        NSLog(@"Download completed with error: %@",error);
        NSLog(@"%@",[NSString stringWithFormat:@"%@",[[task originalRequest]URL]]);
        
        [self.complrteDataDic setObject:[NSNull null] forKey:[NSString stringWithFormat:@"%@",[[task originalRequest]URL]]];
        [self.completeDataErrorDic setObject:error forKey:[NSString stringWithFormat:@"%@",[[task originalRequest]URL]]];
        self.completeTaskCount--;
        self.taskCount--;
        
        
    }else{
        
        NSLog(@"Download finished successfully.");
        
    }
    
    self.completeTaskCount++;
    
    
    
    if ([self.delegate respondsToSelector:@selector(didFinishAllDownloadsWithDataDictinary:withErrorDic:)]){
        
        if (self.completeTaskCount==self.taskCount) {
            
            [self.delegate didFinishAllDownloadsWithDataDictinary:self.complrteDataDic withErrorDic:self.completeDataErrorDic];
            
        }
    }
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        
        NSLog(@"Unknown transfer size");
        
    }else{
        
        if ([self.delegate respondsToSelector:@selector(fileDownloadProgress:)]) {
            
            __block double progress=0.0;
            
            
            [self.taskDataDic setObject:[NSNumber numberWithDouble:(double)totalBytesWritten / (double)totalBytesExpectedToWrite] forKey:[NSString stringWithFormat:@"%@",[[downloadTask originalRequest]URL]]];
            
            
            dispatch_group_t group = dispatch_group_create();
            NSLock *RegulationsInProgress;
            
            for (NSNumber *progressNum in [self.taskDataDic allValues]) {
                
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_group_async(group, queue, ^{
                    
                    [RegulationsInProgress lock];
                    
                    @try {
                        
                        progress=progress+[progressNum doubleValue];
                        
                    }
                    @finally {
                        
                        [RegulationsInProgress unlock];
                        
                    }
                    
                });
                
            }
            
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            
            [self.delegate fileDownloadProgress:[NSNumber numberWithDouble:progress/self.taskCount]];
            
        }
        
    }
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
            
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                
                void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
                
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    completionHandler();
                    
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"ダウンロードが完了しました。";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                    
                }];
            }
        }
    }];
    
}
-(NSArray*)encodeUrlFromJapaneseUrl:(NSArray*)originalUrlArray{
    
    NSLock*addArrayLock=[[NSLock alloc]init];
    NSMutableArray*encodedUrlArray=[[NSMutableArray alloc]init];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSString*urlStr in originalUrlArray) {
        
        dispatch_group_async(group, queue, ^{
            
            [addArrayLock lock];
            
            @try {
                
                CFStringRef originalString=(__bridge CFStringRef)urlStr;
                CFStringRef encodedString=CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,originalString,NULL,(CFStringRef)@"<>{}|^[]`", kCFStringEncodingUTF8);
                NSString*escapedUrl=(__bridge NSString*)encodedString;
                
                [encodedUrlArray addObject:escapedUrl];
                
            }
            @finally {
                
                [addArrayLock unlock];
                
            }
            
        });
        
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return encodedUrlArray;
}
#pragma mark - Cheak duplication url
+(NSArray*)cheakDuplicationURLString:(NSArray*)needCheakArray{
    
    return [[[NSSet alloc]initWithArray:needCheakArray] allObjects];
    
}

@end
