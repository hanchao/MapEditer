//
//  OPEBaseViewController.h
//  OSM POI Editor
//
//  Created by David on 3/27/13.
//
//

#import <UIKit/UIKit.h>
#import "OPEOSMData.h"
#import "MBProgressHUD.h"

@interface OPEBaseViewController : UIViewController <MBProgressHUDDelegate, UIAlertViewDelegate>

@property (nonatomic,strong)OPEOSMData * osmData;
@property (nonatomic,strong)OPEOSMAPIManager * apiManager;
@property (nonatomic,strong)MBProgressHUD * HUD;
@property (nonatomic) NSInteger numberOfOngoingParses;

-(void)startSave;
-(void)showAuthError;
-(void)signIntoOSM;

-(void)findishedAuthWithError:(NSError *)error;

-(void)showCompleteMessage;
-(void)showFailedMessage:(NSError *)error;

@end
