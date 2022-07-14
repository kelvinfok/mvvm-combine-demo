//
//  combine_mvvm_demoTests.swift
//  combine-mvvm-demoTests
//
//  Created by Kelvin Fok on 15/7/22.
//

import XCTest
import Combine
@testable import combine_mvvm_demo

class combine_mvvm_demoTests: XCTestCase {
  
  var sut: QuoteViewModel!
  var quoteService: MockQuoteServiceType!
  
  override func setUp()  {
    quoteService = MockQuoteServiceType()
    sut = QuoteViewModel(quoteServiceType: quoteService)
  }
  
  override func tearDown()  {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  
}

class MockQuoteServiceType: QuoteServiceType {
  
  var value: AnyPublisher<Quote, Error>?
  func getRandomQuote() -> AnyPublisher<Quote, Error> {
    return value ?? Empty().eraseToAnyPublisher()
  }
  
  
}
