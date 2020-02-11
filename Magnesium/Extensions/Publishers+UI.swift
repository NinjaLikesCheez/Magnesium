//
//  Publishers+UI.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

// swiftlint:disable nesting type_name colon

import Combine
import Foundation

extension Publisher {
    func ui() -> Publishers.UI<Self> {
        return .init(upstream: self)
    }
}

extension Publishers {
    struct UI<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure

        let upstream: Upstream

        init(upstream: Upstream) {
            self.upstream = upstream
        }

        func receive<Downstream: Subscriber>(
            subscriber: Downstream
        ) where Upstream.Failure == Downstream.Failure, Upstream.Output == Downstream.Input {
            upstream.subscribe(Inner(downstream: subscriber))
        }
    }
}

extension Publishers.UI {
    private final class Inner<Downstream: Subscriber>:
        Subscriber,
        Subscription,
        CustomStringConvertible,
        CustomReflectable
        where
        Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure
        typealias ReceiveOn = Publishers.UI<Upstream>

        private enum State {
            case ready(Downstream)
            case subscribed(Downstream, Subscription)
            case completed
        }

        private let lock = NSLock()
        private var state: State

        var description: String {
            return "UI"
        }

        var customMirror: Mirror {
            return Mirror(self, children: EmptyCollection())
        }

        init(downstream: Downstream) {
            state = .ready(downstream)
        }

        private func performOnMainThread(_ action: @escaping () -> Void) {
            if Thread.isMainThread {
                action()
            } else {
                DispatchQueue.main.async {
                    action()
                }
            }
        }

        func receive(subscription: Subscription) {
            lock.lock()
            guard case let .ready(downstream) = state else {
                lock.unlock()
                subscription.cancel()
                return
            }
            state = .subscribed(downstream, subscription)
            lock.unlock()
            downstream.receive(subscription: self)
        }

        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard case let .subscribed(downstream, _) = state else {
                lock.unlock()
                return .none
            }
            lock.unlock()
            performOnMainThread { [weak self] in
                self?.performReceive(input, downstream: downstream)
            }
            return .none
        }

        private func performReceive(_ input: Upstream.Output, downstream: Downstream) {
            let demand = downstream.receive(input)
            guard demand > 0 else {
                return
            }
            lock.lock()
            guard case let .subscribed(_, subscription) = state else {
                lock.unlock()
                return
            }
            lock.unlock()
            subscription.request(demand)
        }

        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard case let .subscribed(downstream, _) = state else {
                lock.unlock()
                return
            }
            state = .completed
            lock.unlock()
            performOnMainThread {
                downstream.receive(completion: completion)
            }
        }

        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case let .subscribed(_, subscription) = state else {
                lock.unlock()
                return
            }
            lock.unlock()
            subscription.request(demand)
        }

        func cancel() {
            lock.lock()
            guard case let .subscribed(_, subscription) = state else {
                lock.unlock()
                return
            }
            state = .completed
            lock.unlock()
            subscription.cancel()
        }
    }
}
