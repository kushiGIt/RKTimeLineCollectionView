//
//  GetInformation.m
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/11/19.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "GetInformation.h"

@implementation GetInformation
-(void)getSubmission{
    
    ManageCoreData*mcd=[[ManageCoreData alloc]init];
    
    NSLog(@"%@",[mcd checkDateInEntity:@"DataLifeTime" isDelete:YES]);
    
    [GetAllTimeLine getAllTimeLine:^(NSMutableArray*urlStrArray,NSMutableArray*timelineDataArray){
        
        NSLog(@"%@",timelineDataArray);
        
        NSLog(@"Start get image data.");
        
        NSMutableIndexSet*indexSet=[[NSMutableIndexSet alloc]init];
        NSUInteger index=0;
        NSLock *coredataLock=[[NSLock alloc]init];
        
        
        for (NSString*urlStr in urlStrArray) {
            
            [coredataLock lock];
            
            @try {
                
                if ([mcd checkDupulicationInEntity:@"DataLifeTime" withKey:urlStr]!=NULL) {
                    
                    [indexSet addIndex:index];
                    
                }
                
                index++;
                
            }
            @finally {
                
                [coredataLock unlock];
                
            }
            
        }
        
        [urlStrArray removeObjectsAtIndexes:indexSet];
        
        RKDataDownloader*dataDownloader=[[RKDataDownloader alloc]initWithUrlArray_defaults:[RKDataDownloader cheakDuplicationURLString:urlStrArray]];
        dataDownloader.delegate=self;
        [dataDownloader startDownloads];
        
    }];

}
#pragma mark - RKDownloader delegate
-(void)fileDownloadProgress:(NSNumber *)progress{
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        
        //[self.progressview setProgress:[progress floatValue] animated:YES];
        NSLog(@"%@",progress);
        
        
    });
    
}
-(void)didFinishDownloadData:(NSData *)data withError:(NSError *)readingDataError dataWithUrl:(NSString *)urlStr{
    
    NSDate*now=[NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone]secondsFromGMT]];
    
    ManageCoreData*mcd=[[ManageCoreData alloc]init];
    [mcd setContextData:data forKey:urlStr ObjectDeleteTime:[now dateByAddingTimeInterval:60*60*24] ischeckDupulicationInEntity:YES withEntityName:@"DataLifeTime"];
    
}
-(void)didFinishAllDownloadsWithDataDictinary:(NSDictionary *)dataDic withErrorDic:(NSDictionary *)errorDic{
    
    //ManageCoreData*mcd=[[ManageCoreData alloc]init];
    //NSLog(@"%@",[mcd checkDateInEntity:@"DataLifeTime" isDelete:NO]);
    
}
@end
