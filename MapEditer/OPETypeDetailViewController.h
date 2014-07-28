//
//  OPETypeDetailViewController.h
//  MapEditer
//
//  Created by chao han on 14-7-28.
//
//

#import <UIKit/UIKit.h>
#import "OPEReferencePoi.h"

@interface OPETypeDetailViewController : UIViewController
{
    UIImageView *imageView;
    UILabel *label;
}

@property (nonatomic, strong) OPEReferencePoi * referencePoi;

@end
