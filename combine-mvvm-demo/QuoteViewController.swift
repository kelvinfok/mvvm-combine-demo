//
//  ViewController.swift
//  combine-mvvm-demo
//
//  Created by Kelvin Fok on 15/7/22.
//

import UIKit
import Combine

class QuoteViewModel {
  
  enum Input {
    case viewDidAppear
    case refreshButtonDidTap
  }
  
  enum Output {
    case fetchQuoteDidFail(error: Error)
    case fetchQuoteDidSucceed(quote: Quote)
    case toggleButton(isEnabled: Bool)
  }
  
  private let quoteServiceType: QuoteServiceType
  private let output: PassthroughSubject<Output, Never> = .init()
  private var cancellables = Set<AnyCancellable>()
  
  init(quoteServiceType: QuoteServiceType = QuoteService()) {
    self.quoteServiceType = quoteServiceType
  }
  
  func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
    input.sink { [weak self] event in
      switch event {
      case .viewDidAppear, .refreshButtonDidTap:
        self?.handleGetRandomQuote()
      }
    }.store(in: &cancellables)
    return output.eraseToAnyPublisher()
  }
  
  private func handleGetRandomQuote() {
    output.send(.toggleButton(isEnabled: false))
    quoteServiceType.getRandomQuote().sink { [weak self] completion in
      self?.output.send(.toggleButton(isEnabled: true))
      if case .failure(let error) = completion {
        self?.output.send(.fetchQuoteDidFail(error: error))
      }
    } receiveValue: { [weak self] quote in
      self?.output.send(.fetchQuoteDidSucceed(quote: quote))
    }.store(in: &cancellables)
  }
}

class QuoteViewController: UIViewController {

  @IBOutlet weak var quoteLabel: UILabel!
  @IBOutlet weak var refreshButton: UIButton!
  
  private let vm = QuoteViewModel()
  private let input: PassthroughSubject<QuoteViewModel.Input, Never> = .init()
  private var cancellables = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bind()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    input.send(.viewDidAppear)
  }
  
  private func bind() {
    let output = vm.transform(input: input.eraseToAnyPublisher())
    output
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
      switch event {
      case .fetchQuoteDidSucceed(let quote):
        self?.quoteLabel.text = quote.content
      case .fetchQuoteDidFail(let error):
        self?.quoteLabel.text = error.localizedDescription
      case .toggleButton(let isEnabled):
        self?.refreshButton.isEnabled = isEnabled
      }
    }.store(in: &cancellables)
    
  }

  @IBAction func refreshButtonTapped(_ sender: Any) {
    input.send(.refreshButtonDidTap)
  }
}

protocol QuoteServiceType {
  func getRandomQuote() -> AnyPublisher<Quote, Error>
}

class QuoteService: QuoteServiceType {
  
  func getRandomQuote() -> AnyPublisher<Quote, Error> {
    let url = URL(string: "https://api.quotable.io/random")!
    return URLSession.shared.dataTaskPublisher(for: url)
      .catch { error in
        return Fail(error: error).eraseToAnyPublisher()
      }.map({ $0.data })
      .decode(type: Quote.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }
}

struct Quote: Decodable {
  let content: String
  let author: String
}
