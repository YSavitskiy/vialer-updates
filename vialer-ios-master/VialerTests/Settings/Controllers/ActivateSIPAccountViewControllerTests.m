//
//  ActivateSIPAccountViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "ActivateSIPAccountViewController.h"
#import <OCMock/OCMock.h>
#import "UserProfileWebViewController.h"
#import "SystemUser.h"
@import XCTest;

@interface ActivateSIPAccountViewControllerTests : XCTestCase
@property (strong, nonatomic) ActivateSIPAccountViewController *activateSIPAccountVC;
@end

@implementation ActivateSIPAccountViewControllerTests

- (void)setUp {
    [super setUp];
    self.activateSIPAccountVC = [[UIStoryboard storyboardWithName:@"SettingsStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ActivateSIPAccountViewController"];
    [self.activateSIPAccountVC loadViewIfNeeded];
}

- (void)tearDown {
    self.activateSIPAccountVC = nil;
    [super tearDown];
}

- (void)testBackButtonWillPopViewController {
    id mockActivateSIPAccountVC = OCMPartialMock(self.activateSIPAccountVC);
    id mockNavigationController = OCMClassMock([UINavigationController class]);
    OCMStub([mockActivateSIPAccountVC navigationController]).andReturn(mockNavigationController);
    
    id mockSystemUser = OCMClassMock([SystemUser class]);
    OCMStub([mockActivateSIPAccountVC user]).andReturn(mockSystemUser);
    OCMStub([mockSystemUser updateSystemUserFromVGWithCompletion:nil]);

    [self.activateSIPAccountVC backButtonPressed:nil];
    OCMVerify([mockNavigationController popViewControllerAnimated:YES]);
    
    [mockActivateSIPAccountVC stopMocking];
    [mockNavigationController stopMocking];
    [mockSystemUser stopMocking];
}

- (void)testPrepareForSegueWillSetNextURL {
    id mockUserProfileWVC = OCMClassMock([UserProfileWebViewController class]);
    id mockSegue = OCMClassMock([UIStoryboardSegue class]);
    OCMStub([mockSegue destinationViewController]).andReturn(mockUserProfileWVC);

    [self.activateSIPAccountVC prepareForSegue:mockSegue sender:nil];

    OCMVerify([mockUserProfileWVC nextUrl:[OCMArg isEqual:@"/user/change/"]]);

    [mockUserProfileWVC stopMocking];
    [mockSegue stopMocking];
}

@end
