//
//  GetInformation.h
//  RKGetTimeLine
//
//  Created by RyousukeKushihata on 2014/11/19.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GetAllTimeLine.h"
#import "RKDataDownloader.h"
#import "ManageCoreData.h"

@class GetInformation;
@protocol GetInformationDelegate <NSObject>

typedef void (^CallbackHandler)(NSMutableArray*timelineDataArray);

@end

@interface GetInformation : NSObject<RKDataDownloaderDelegate>{
    
}

-(void)getSubmission;


//@property(nonatomic,weak)id<GetAllTimeLineDelegate>delegate;

@end
