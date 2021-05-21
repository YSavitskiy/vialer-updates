//
//  SettingsViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SettingsViewController.h"

#import "ActivateSIPAccountViewController.h"
#import "EditNumberViewController.h"
#import "SIPUtils.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
#import "Vialer-Swift.h"

static int const SettingsViewControllerNumbersSection       = 0;
static int const SettingsViewControllerMyNumberRow          = 0;
static int const SettingsViewControllerOutgoingNumberRow    = 1;
static int const SettingsViewControllerMyEmailRow           = 2;
static int const SettingsViewControllerSipAccountRow        = 3;

static int const SettingsViewControllerVoIPAccountSection   = 1;
static int const SettingsViewControllerSipEnabledRow        = 0;
static int const SettingsViewControllerWifiNotificationRow  = 1;
static int const SettingsViewControllerAudioQualityRow      = 2;
static int const SettingsViewControllerRingtoneRow      = 3;


static int const SettingsViewControllerAdvancedSection       = 2;
static int SettingsViewControllerUseTLSRow                  = 0;
static int SettingsViewControllerUseStunServersRow          = 1;

static int const SettingsViewControllerDebugSection         = 3;
static int const SettingsViewControllerSubmitFeedbackRow    = 0;
static int const SettingsViewControllerLoggingEnabledRow    = 1;

static int const SettingsViewControllerUISwitchWidth            = 60;
static int const SettingsViewControllerUISwitchOriginOffsetX    = 35;
static int const SettingsViewControllerUISwitchOriginOffsetY    = 15;

static int const SettingsViewControllerSwitchVoIP               = 1001;
static int const SettingsViewControllerSwitchWifiNotification   = 1002;
static int const SettingsViewControllerSwitchLogging            = 1004;
static int const SettingsViewControllerSwitchUseTLS             = 1006;
static int const SettingsViewControllerSwitchUseStunServers     = 1007;
static int const SettingsViewControllerSwitchUsePhoneRingtone     = 1008;

static NSString * const SettingsViewControllerShowEditNumberSegue       = @"ShowEditNumberSegue";
static NSString * const SettingsViewControllerShowActivateSIPAccount = @"ShowActivateSIPAccount";
static NSString * const SettingsViewControllerShowAudioQualitySegue = @"ShowAudioQualitySegue";
static NSString * const SettingsViewControllerShowFeedbackSegue = @"ShowFeedbackFormSegue";

@interface SettingsViewController() <EditNumberViewControllerDelegate>
@property (weak, nonatomic) SystemUser *currentUser;
@property (nonatomic) BOOL useTCP;
@end

@implementation SettingsViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self tableView].estimatedRowHeight = 85.0;
    [self tableView].rowHeight = UITableViewAutomaticDimension;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outgoingNumberUpdated:) name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [VialerGAITracker trackScreenForControllerWithName:NSStringFromClass([self class])];

    if (self.showSIPAccountWebview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:SettingsViewControllerShowActivateSIPAccount sender:self];
        });
    } else {
        [self.tableView reloadData];
    }
    [self.currentUser addObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled)) options:0 context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.currentUser removeObserver:self forKeyPath:NSStringFromSelector(@selector(sipEnabled))];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SystemUserOutgoingNumberUpdatedNotification object:nil];
}

#pragma mark - Properties

- (SystemUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [SystemUser currentUser];
    }
    return _currentUser;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SettingsViewControllerNumbersSection:
            // Always 3
            // - My number
            // - Outgoing number
            // - Email address
            // account ID
            return self.currentUser.sipEnabled ? 4 : 3;
            break;

        case SettingsViewControllerVoIPAccountSection:
            if (self.currentUser.sipEnabled) {
                // The VoIP Switch
                // WiFi notification
                // Audio Quality
                return 4;
            } else {
                // Only show VoIP Switch
                return 1;
            }
            break;

        case SettingsViewControllerAdvancedSection:
            if (self.currentUser.sipEnabled) {
                // Remotelogging enabled (2)
                // TLS
                // use stun servers
                return 2;
            } else {
                // Remotelogging enabled (2)
                return 0;
            }
            break;

        case SettingsViewControllerDebugSection:
            return 2;

        default:
            return 0;
            break;
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableViewSettingsCell = @"SettingsCell";
    static NSString *tableViewSettingsWithAccessoryCell = @"SettingsWithAccessoryCell";
    static NSString *tableViewSettingsWithSwitchCell = @"SettingsWithSwitchCell";

    UITableViewCell *cell;

    // Specific config according to cell function.
    if (indexPath.section == SettingsViewControllerNumbersSection) {
        if (indexPath.row == SettingsViewControllerMyNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithAccessoryCell];
            cell.textLabel.text = NSLocalizedString(@"My number", nil);
            cell.detailTextLabel.text = self.currentUser.mobileNumber;

        } else if (indexPath.row == SettingsViewControllerOutgoingNumberRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Outgoing number", nil);
            cell.detailTextLabel.text = self.currentUser.outgoingNumber;

        } else if (indexPath.row == SettingsViewControllerMyEmailRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"Email address", nil);
            cell.detailTextLabel.minimumScaleFactor = 0.8f;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = self.currentUser.username;
        }
        else if (indexPath.row == SettingsViewControllerSipAccountRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsCell];
            cell.textLabel.text = NSLocalizedString(@"VoIP account ID", nil);
            cell.detailTextLabel.text = self.currentUser.sipAccount;
        }
    } else if (indexPath.section == SettingsViewControllerVoIPAccountSection) {
        if (indexPath.row == SettingsViewControllerSipEnabledRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Enable VoIP", nil)
                          withTag:SettingsViewControllerSwitchVoIP
                       defaultVal:self.currentUser.sipEnabled
                       withDetail:nil];
        } else if (indexPath.row == SettingsViewControllerWifiNotificationRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Enable WiFi notification", nil)
                          withTag:SettingsViewControllerSwitchWifiNotification
                       defaultVal:self.currentUser.showWiFiNotification
                       withDetail:nil];
        } else if (indexPath.row == SettingsViewControllerAudioQualityRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithAccessoryCell];
            cell.textLabel.text = NSLocalizedString(@"Audio quality", nil);
            if (self.currentUser.currentAudioQuality == AudioQualityLow) {
                cell.detailTextLabel.text = NSLocalizedString(@"Standard audio", @"Standard audio");
            } else if (self.currentUser.currentAudioQuality == AudioQualityHigh) {
                cell.detailTextLabel.text = NSLocalizedString(@"Higher quality audio", @"Higher quality audio");
            }
        }
        else if (indexPath.row == SettingsViewControllerRingtoneRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle:NSLocalizedString(@"Use phone ringtone", nil)
                          withTag:SettingsViewControllerSwitchUsePhoneRingtone
                       defaultVal:self.currentUser.usePhoneRingtone
                       withDetail:NSLocalizedString(self.currentUser.usePhoneRingtone ?
                               @"Incoming calls will use the phone\'s current ringtone."
                               : @"Incoming calls will use a special ringtone specific to this application.", nil)
            ];
        }
    } else if (indexPath.section == SettingsViewControllerAdvancedSection) {
        if (indexPath.row == SettingsViewControllerUseTLSRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell
                        withTitle:NSLocalizedString(@"Use encrypted calling", @"Use encrypted calling")
                          withTag:SettingsViewControllerSwitchUseTLS
                       defaultVal:self.currentUser.useTLS
                       withDetail:nil];
        } else if (indexPath.row == SettingsViewControllerUseStunServersRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell
                        withTitle:NSLocalizedString(@"Use STUN for calling", @"Use STUN for calling")
                          withTag:SettingsViewControllerSwitchUseStunServers
                       defaultVal:self.currentUser.useStunServers
                       withDetail:nil];
        }
    }
    else if (indexPath.section == SettingsViewControllerDebugSection) {
        if (indexPath.row == SettingsViewControllerLoggingEnabledRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:tableViewSettingsWithSwitchCell];
            [self createOnOffView:cell withTitle: NSLocalizedString(@"Remote Logging", nil)
                          withTag:SettingsViewControllerSwitchLogging
                       defaultVal:[VialerLogger remoteLoggingEnabled]
                       withDetail:NSLocalizedString(@"Automatically share your app activity with our developers and support team to help resolve issues and errors", nil)];
        }
        else if (indexPath.row == SettingsViewControllerSubmitFeedbackRow) {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"sendFeedback"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sendFeedback"];
            }
            cell.textLabel.text =NSLocalizedString(@"Send Feedback", nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Report issues or suggest new features", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.enabled = YES;
        }
    }
    return cell;
}

#pragma mark - actions

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SettingsViewControllerShowEditNumberSegue]) {
        EditNumberViewController *editNumberController = (EditNumberViewController *)segue.destinationViewController;
        editNumberController.numberToEdit = self.currentUser.mobileNumber;
        editNumberController.delegate = self;
    } else if ([segue.identifier isEqualToString:SettingsViewControllerShowActivateSIPAccount]) {
        ActivateSIPAccountViewController *activateSIPAccountViewController = (ActivateSIPAccountViewController *)segue.destinationViewController;
        if (self.showSIPAccountWebview) {
            activateSIPAccountViewController.backButtonToRootViewController = YES;
            self.showSIPAccountWebview = NO;
        }
    }
}

- (void)unwindToSettingsViewController:(UIStoryboardSegue *)sender {}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsViewControllerNumbersSection && indexPath.row == SettingsViewControllerMyNumberRow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:SettingsViewControllerShowEditNumberSegue sender:self];
        });
    } else if (indexPath.section == SettingsViewControllerVoIPAccountSection && indexPath.row == SettingsViewControllerAudioQualityRow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:SettingsViewControllerShowAudioQualitySegue sender:self];
        });
    } else if (indexPath.section == SettingsViewControllerDebugSection && indexPath.row == SettingsViewControllerSubmitFeedbackRow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:SettingsViewControllerShowFeedbackSegue sender:self];
        });
    }
}

#pragma mark - EditNumberViewControllerDelegate delegate

- (void)numberHasChanged:(NSString *)newNumber {
    // Update the tableView Cell.
    NSIndexPath *rowAtIndexPath = [NSIndexPath indexPathForRow:SettingsViewControllerMyNumberRow
                                                     inSection:SettingsViewControllerNumbersSection];
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:rowAtIndexPath];
    myNumberCell.detailTextLabel.text = self.currentUser.mobileNumber;
}

#pragma mark - Enable VoIP switch handler

- (void)didChangeSwitch:(UISwitch *)sender {
    if (sender.tag == SettingsViewControllerSwitchVoIP) {
        if (sender.isOn) {
            [self tryToEnableSIPWithSwitch:sender];
        } else {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Disabling VoIP...", nil)];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                self.currentUser.sipEnabled = NO;
            });
        }
    } else if (sender.tag == SettingsViewControllerSwitchWifiNotification) {
        self.currentUser.showWiFiNotification = sender.isOn;
    } else if (sender.tag == SettingsViewControllerSwitchUseTLS) {
        self.currentUser.useTLS = sender.isOn;
    } else if (sender.tag == SettingsViewControllerSwitchUseStunServers) {
        self.currentUser.useStunServers = sender.isOn;
    } else if (sender.tag == SettingsViewControllerSwitchLogging) {
        [VialerLogger setRemoteLoggingEnabled:sender.isOn];
        VialerLogVerbose(sender.isOn ? @"Remote logging enabled" : @"Remote logging disabled");
        NSIndexSet *indexSetWithIndex = [NSIndexSet indexSetWithIndex:SettingsViewControllerDebugSection];
        [self.tableView  reloadSections:indexSetWithIndex withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (sender.tag == SettingsViewControllerSwitchUsePhoneRingtone) {
        self.currentUser.usePhoneRingtone = sender.isOn;
        [self.tableView reloadData];
    }
}


- (void)tryToEnableSIPWithSwitch:(UISwitch *)sender {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading VoIP settings...", nil)];
    [self.currentUser getAndActivateSIPAccountWithCompletion:^(BOOL success, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            // Fetching account failed.
            [self presentViewController:[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to load VoIP settings.", nil)
                                                                            message:NSLocalizedString(@"Unable to load your VoIP settings. Please try again.", nil)
                                                               andDefaultButtonText:NSLocalizedString(@"Ok", nil)]
                               animated:YES
                             completion:nil];
            sender.on = NO;
        } else if (!success) {
            // There is no account, show info page.
            sender.on = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:SettingsViewControllerShowActivateSIPAccount sender:self];
            });
        } else {
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Helper function for switches in table

- (void)createOnOffView:(UITableViewCell*)cell withTitle:(NSString*)title withTag:(int)tag defaultVal:(BOOL)defaultVal withDetail:(NSString*)detail {
    cell.textLabel.text = title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = detail;
    cell.detailTextLabel.enabled = (detail != nil) ? YES : NO;

    CGRect rect;
    rect = cell.contentView.frame;
    rect.origin.x = rect.size.width / 2 + SettingsViewControllerUISwitchOriginOffsetX;
    rect.origin.y = rect.size.height / 2 - SettingsViewControllerUISwitchOriginOffsetY;
    rect.size.width = SettingsViewControllerUISwitchWidth;

    UISwitch *switchView = [[UISwitch alloc] initWithFrame:rect];
    [switchView addTarget:self action:@selector(didChangeSwitch:) forControlEvents:UIControlEventValueChanged];
    switchView.tag = tag;
    [switchView setOn:defaultVal];

    cell.accessoryView = switchView;
}

#pragma mark - Notifications / KVO

- (void)outgoingNumberUpdated:(NSNotification *)noticiation {
    NSIndexPath *rowAtIndexPath = [NSIndexPath indexPathForRow:SettingsViewControllerOutgoingNumberRow
                                                     inSection:SettingsViewControllerNumbersSection];
    UITableViewCell *myNumberCell = [self.tableView cellForRowAtIndexPath:rowAtIndexPath];
    myNumberCell.detailTextLabel.text = self.currentUser.outgoingNumber;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // React to changes on the SipAllowed property of the SystemUser.
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(sipEnabled))] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        });
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if ([self tableView:tableView numberOfRowsInSection:section] <= 0) {
        return nil;
    }

    switch (section) {
        case SettingsViewControllerVoIPAccountSection:
            return NSLocalizedString(@"Call settings", nil);
        case SettingsViewControllerNumbersSection:
            return NSLocalizedString(@"Account", nil);
        case SettingsViewControllerAdvancedSection:
            return NSLocalizedString(@"Advanced call settings", nil);
        case SettingsViewControllerDebugSection:
            return NSLocalizedString(@"Debug settings", nil);
    }
    
    return @"";
}

@end
