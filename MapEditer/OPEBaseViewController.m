//
//  OPEBaseViewController.m
//  OSM POI Editor
//
//  Created by David on 3/27/13.
//
//

#import "OPEBaseViewController.h"
#import "OPEStrings.h"

#import "OPELog.h"
#import "OPEAPIConstants.h"
#import "GTMOAuthViewControllerTouch.h"

#define authErrorTag 101

@interface OPEBaseViewController ()

@end

@implementation OPEBaseViewController
@synthesize HUD,numberOfOngoingParses;
@synthesize osmData = _osmData;
@synthesize apiManager = _apiManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.numberOfOngoingParses = 0;
}

-(OPEOSMAPIManager *)apiManager
{
    if (!_apiManager) {
        _apiManager = [[OPEOSMAPIManager alloc] init];
    }
    return _apiManager;
}

-(OPEOSMData *)osmData
{
    if(!_osmData)
    {
        _osmData = [[OPEOSMData alloc] init];
    }
    return _osmData;
}

-(void)showAuthError
{
    if (HUD)
    {
        [HUD hide:YES];
    }
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:OAUTH_ERROR_STRING
                                                      message:LOGIN_ERROR_STRING
                                                     delegate:self
                                            cancelButtonTitle:CANCEL_STRING
                                            otherButtonTitles:LOGIN_STRING, nil];
    message.tag = authErrorTag;
    [message show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == authErrorTag && buttonIndex != alertView.cancelButtonIndex)
    {
        [self signIntoOSM];
    }
}

- (void)signIntoOSM {
    
    
    NSURL *requestURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/request_token"];
    NSURL *accessURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/authorize"];
    NSString *scope = @"http://api.openstreetmap.org/";
    
    GTMOAuthAuthentication *auth = [OPEOSMAPIManager osmAuth];
    if (auth == nil) {
        // perhaps display something friendlier in the UI?
        DDLogInfo(@"A valid consumer key and consumer secret are required for signing in to OSM");
    }
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.google.com/OAuthCallback"];
    
    // Display the autentication view
    GTMOAuthViewControllerTouch * viewController = [[GTMOAuthViewControllerTouch alloc]
                                                    initWithScope:scope
                                                    language:nil
                                                    requestTokenURL:requestURL
                                                    authorizeTokenURL:authorizeURL
                                                    accessTokenURL:accessURL
                                                    authentication:auth
                                                    appServiceName:@"MapEditor"
                                                    delegate:self
                                                    finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController
                                           animated:YES];
}


- (void)viewController:(GTMOAuthViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuthAuthentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        DDLogError(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"];// kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[NSString alloc] initWithData:responseData
                                                  encoding:NSUTF8StringEncoding];
            DDLogInfo(@"%@", str);
        }
        
        //[self setAuthentication:nil];
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //   [auth authorizeRequest:myNSURLMutableRequest]
        //
        // or store the authentication object into a GTM service object like
        //
        //   [[self contactService] setAuthorizer:auth];
        
        // save the authentication object
        //[self setAuthentication:auth];
        
        // Just to prove we're signed in, we'll attempt an authenticated fetch for the
        // signed-in user
        //[self doAnAuthenticatedAPIFetch];
        DDLogInfo(@"Suceeed");
        
        //[self dismissModalViewControllerAnimated:YES];
    }
    [self findishedAuthWithError:error];
    //[self updateUI];
}

-(void)findishedAuthWithError:(NSError *)error
{
    DDLogError(@"AUTH ERROR: %@",error);
}


-(void)startSave
{
    [self.view addSubview:HUD];
    self.HUD.mode = MBProgressHUDModeIndeterminate;
    [HUD setLabelText:[NSString stringWithFormat:@"%@...",SAVING_STRING]];
    [HUD show:YES];
}


-(void)showCompleteMessage
{
    [self.view addSubview:self.HUD];
    self.HUD.mode = MBProgressHUDModeCustomView;
    self.HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]];
    self.HUD.labelText = COMPLETE_STRING;
    [self.HUD show:YES];
    [self.HUD hide:YES afterDelay:1.0];
}
-(void)showFailedMessage:(NSError *)error
{
    [self.view addSubview:self.HUD];
    self.HUD.mode = MBProgressHUDModeCustomView;
    self.HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"x.png"]];
    self.HUD.labelText = ERROR_STRING;
    [self.HUD show:YES];
    [self.HUD hide:YES afterDelay:2.0];
}

@end
