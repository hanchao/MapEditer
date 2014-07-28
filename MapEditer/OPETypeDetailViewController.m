//
//  OPETypeDetailViewController.m
//  MapEditer
//
//  Created by chao han on 14-7-28.
//
//

#import "OPETypeDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AFNetworking.h"

@interface OPETypeDetailViewController ()

@end

@implementation OPETypeDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIScrollView * scrolView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrolView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrolView];
    
    //https://taginfo.openstreetmap.org/api/4/tag/wiki_pages?key=shop&value=outdoor
    NSMutableString *URLString = [NSMutableString new];
    [URLString appendString:@"https://taginfo.openstreetmap.org/api/4/tag/wiki_pages?"];
    for(NSString * osmKey in _referencePoi.tags)
    {
        [URLString appendFormat:@"key=%@&value=%@",osmKey,_referencePoi.tags[osmKey]];
        break;
    }
    
    NSMutableURLRequest * request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setTimeoutInterval:20];
    AFHTTPRequestOperation * requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer=[AFHTTPResponseSerializer serializer];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *taginfos = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        
        for(NSDictionary * taginfo in taginfos)
        {
            NSString *lang = taginfo[@"lang"];
            NSLog(@"Success %@",taginfo[@"lang"]);
            if ([lang isEqualToString:@"en"]) {
                NSString *description = taginfo[@"description"];
                
                CGSize labelSize = [description sizeWithFont:[UIFont boldSystemFontOfSize:17.0f]
                                   constrainedToSize:CGSizeMake(280, 100)
                                       lineBreakMode:UILineBreakModeCharacterWrap];   // str是要显示的字符串
                label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelSize.width, labelSize.height)];
                label.text = description;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont boldSystemFontOfSize:17.0f];
                label.numberOfLines = 0;// 不可少Label属性之一
                label.lineBreakMode = UILineBreakModeCharacterWrap;// 不可少Label属性之二
                [scrolView addSubview:label];

                
                NSDictionary * image = taginfo[@"image"];
                if (image != nil) {
                    int width = [image[@"width"] intValue];
                    int height = [image[@"height"] intValue];
                    if(width == 0 || height == 0)
                        return;
                    
                    NSString *image_url = image[@"image_url"];
                    NSString *url_prefix = image[@"thumb_url_prefix"];
                    NSString *url_suffix = image[@"thumb_url_suffix"];
                    
                    int viewwidth = self.view.bounds.size.width;
                    if ([[UIScreen mainScreen] scale] > 1.0){
                        viewwidth *= 2;
                    }
                    
                    NSString *url_string = [NSString stringWithFormat:@"%@%d%@",url_prefix,viewwidth,url_suffix];
                    
                    double widthScale = width/self.view.bounds.size.width;
                    double heightScale = height/self.view.bounds.size.height;
                    
                    double maxScale = MAX(widthScale, heightScale);

                    CGRect labelFrame = CGRectMake(0,labelSize.height, width/maxScale, height/maxScale);
                    imageView = [[UIImageView alloc] initWithFrame:labelFrame];
                    [scrolView addSubview:imageView];
                    
                    [imageView setImageWithURL:[NSURL URLWithString:url_string]
                              placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                         if (error!=nil) {
                                             NSLog(@"error");
                                             [imageView setImageWithURL:[NSURL URLWithString:image_url]
                                                       placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                                              completed:nil];
                                         }
                                     }];
                    
                }
                
                break;
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure");
        
    }];
    [requestOperation start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:MyIdentifier];
    }
    
    // Here we use the new provided setImageWithURL: method to load the web image
    NSString *urlString = @"http://wiki.openstreetmap.org/w/images/0/02/Outdoor_shop.png";
    
    //cell.imageView.image = [UIImage imageNamed:@"note_closed.png"];
    [cell.imageView setImageWithURL:[NSURL URLWithString:urlString]
                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    
    //[cell.imageView setFrame:CGRectMake(0, 0, 30, 30)];
    
//    [cell.imageView setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
//                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    
    cell.textLabel.text = @"My Text";
    return cell;
}

@end
