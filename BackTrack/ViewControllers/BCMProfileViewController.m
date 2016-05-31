#import "BCMProfileViewController.h"
#import <CMHealth/CMHealth.h>
#import <MessageUI/MessageUI.h>
#import "UIViewController+BCM.h"
#import "UIButton+BCM.h"
#import "BCMMainThread.h"

@interface BCMProfileViewController ()<MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (nonatomic, nullable) MFMailComposeViewController *mailViewController;
@end

@implementation BCMProfileViewController

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[CMHUser currentUser] addObserver:self forKeyPath:@"userData" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:nil];

    [self.logOutButton setCornerRadius:4.0f andBorderWidth:1.0f];
    self.mailViewController = [BCMProfileViewController mailComposeViewControllerWithDelegate:self];
}

- (void)dealloc
{
    [[CMHUser currentUser] removeObserver:self forKeyPath:@"userData"];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == [CMHUser currentUser] && [@"userData" isEqualToString:keyPath]) {
        on_main_thread(^{
            self.userEmailLabel.text = [CMHUser currentUser].userData.email;
        });
    }
}

#pragma mark Target-Action

- (IBAction)didPressLogoutButton:(UIButton *)sender
{
    NSLog(@"Did Press Logout");
}

- (IBAction)didPressWebsiteButton:(UIButton *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://cloudmineinc.com"]];
}

- (IBAction)didPressEmailButton:(UIButton *)sender
{
    if (nil == self.mailViewController) {
        [self showAlertWithMessage:NSLocalizedString(@"The mail app is not configured on your device.", nil) andError:nil];
        return;
    }

    [self presentViewController:self.mailViewController animated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultFailed) {
        [self.presentedViewController showAlertWithMessage:NSLocalizedString(@"Something went wrong sending your message", nil) andError:error];
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];

    if (result != MFMailComposeResultSent) {
        return;
    }

    [self showAlertWithMessage:NSLocalizedString(@"Thanks for reaching out! Someone will get back to your shortly.", nil) andError:error];
}

#pragma mark Private

+ (MFMailComposeViewController *)mailComposeViewControllerWithDelegate:(id<MFMailComposeViewControllerDelegate>)delegate
{
    if (![MFMailComposeViewController canSendMail]) {
        return nil;
    }

    MFMailComposeViewController* composeVC = [MFMailComposeViewController new];
    composeVC.mailComposeDelegate = delegate;
    [composeVC setToRecipients:@[@"sales@cloudmineinc.com"]];
    [composeVC setSubject:@"CHC inquiry - BackTrack"];
    [composeVC setMessageBody:@"I would like to learn more about CareKit and the CloudMine Connected Health Cloud." isHTML:NO];

    return composeVC;
}

@end
