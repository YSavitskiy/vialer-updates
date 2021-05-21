//
//  MiddlewareRequestOperationManagerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "Vialer-Swift.h"
#import "Middleware.h"
#import "MiddlewareRequestOperationManager.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
@import XCTest;

@interface Middleware()
- (MiddlewareRequestOperationManager *)commonMiddlewareRequestOperationManager;
@end

@interface MiddlewareRequestOperationManagerTests : XCTestCase
@property (strong, nonatomic) MiddlewareRequestOperationManager *middlewareRequestOperationManager;
@property (strong, nonatomic) NSString *middlewareBaseURLAsString;
@end

@implementation MiddlewareRequestOperationManagerTests

- (void)setUp {
    [super setUp];
    
    //To ensure an equal middleware API setup as actually used by the middleware class.
    Middleware *aMiddlewareInstance = [[Middleware alloc] init];
    self.middlewareRequestOperationManager = [aMiddlewareInstance commonMiddlewareRequestOperationManager];
    self.middlewareBaseURLAsString = [[UrlsConfiguration shared] middlewareBaseUrl];
}

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
    self.middlewareBaseURLAsString = nil;
    self.middlewareRequestOperationManager = nil;
    [super tearDown];
}

- (void)testUpdateDeviceRecordFail502 {
    //Given
    NSString *mockAPNSToken = @"0000000011111111222222223333333344444444555555556666666677777777";
    NSString *mockSIPAccount = @"42";
    int statusCodeToReturn = 502;
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Match the requested url with the url from the middleware as per configuration class/plist
        NSString *requestSchemeAndHost = [NSString stringWithFormat:@"%@://%@", request.URL.scheme, request.URL.host];
        return [requestSchemeAndHost isEqualToString:self.middlewareBaseURLAsString];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:statusCodeToReturn headers:nil];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Creating device record"];
    
    //When
    [self.middlewareRequestOperationManager updateDeviceRecordWithAPNSToken:mockAPNSToken sipAccount:mockSIPAccount withCompletion:^(NSError *error) {
        if (!error) {
            XCTFail(@"An error should have occurred.");
        } else {
            //Then
            NSHTTPURLResponse *response = [[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            XCTAssert(response.statusCode == statusCodeToReturn,
                      @"Unexpected HTTP status code returned, expected: %d, received: %ld", statusCodeToReturn, (long)response.statusCode);
        }
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation error");
        }
    }];
}

- (void)testSentCallResponseFailsWith408 {
    //Given
    NSDictionary *payload = @{@"unique_key": @1234,
                              @"message_start_time" : @1234,
                              };
    int statusCodeToReturn = VoIPGRIDHttpErrorRequestTimeout;
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Match the requested url with the url from the middleware as per configuration class/plist
        NSString *requestSchemeAndHost = [NSString stringWithFormat:@"%@://%@", request.URL.scheme, request.URL.host];
        return [requestSchemeAndHost isEqualToString:self.middlewareBaseURLAsString];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:statusCodeToReturn headers:nil];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call response to middleware"];
    
    //When
    [self.middlewareRequestOperationManager sentCallResponseToMiddleware:payload isAvailable:NO withCompletion:^(NSError *error) {
        if (!error) {
            XCTFail(@"An error should have occurred.");
        } else {
            //Then
            NSHTTPURLResponse *response = [[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            XCTAssert(response.statusCode == statusCodeToReturn,
                      @"Unexpected HTTP status code returned, expected: %d, received: %ld", statusCodeToReturn, (long)response.statusCode);
            
        }
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation error");
        }
    }];
}

@end
