//
//  AnyTorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

@inline(never)
private func _abstract(
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    fatalError("Method must be overridden", file: file, line: line)
}

private class _AnyTorrentListItemViewModelBoxBase: TorrentListItemViewModel {
    var base: Any { _abstract() }
    var name: AnyPublisher<String, Never> { _abstract() }
    var progress: AnyPublisher<Float, Never> { _abstract() }
    var progressColor: AnyPublisher<UIColor, Never> { _abstract() }
    var state: AnyPublisher<String, Never> { _abstract() }
    var speed: AnyPublisher<String, Never> { _abstract() }
    var progressString: AnyPublisher<String, Never> { _abstract() }
    var ratioOrETA: AnyPublisher<String, Never> { _abstract() }

    static func == (lhs: _AnyTorrentListItemViewModelBoxBase, rhs: _AnyTorrentListItemViewModelBoxBase) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func hash(into hasher: inout Hasher) { _abstract() }
    func isEqual(to other: _AnyTorrentListItemViewModelBoxBase) -> Bool { _abstract() }
}

private final class _AnyTorrentListItemViewModelBox<
    Base: TorrentListItemViewModel
>: _AnyTorrentListItemViewModelBoxBase {
    private let _base: Base

    override var base: Any { _base }
    override var name: AnyPublisher<String, Never> { _base.name }
    override var progress: AnyPublisher<Float, Never> { _base.progress }
    override var progressColor: AnyPublisher<UIColor, Never> { _base.progressColor }
    override var state: AnyPublisher<String, Never> { _base.state }
    override var speed: AnyPublisher<String, Never> { _base.speed }
    override var progressString: AnyPublisher<String, Never> { _base.progressString }
    override var ratioOrETA: AnyPublisher<String, Never> { _base.ratioOrETA }

    init(_ base: Base) {
        _base = base
    }

    override func hash(into hasher: inout Hasher) {
        _base.hash(into: &hasher)
    }

    override func isEqual(to other: _AnyTorrentListItemViewModelBoxBase) -> Bool {
        guard let other = other as? _AnyTorrentListItemViewModelBox<Base> else { return false }
        return _base == other._base
    }
}

struct AnyTorrentListItemViewModel: TorrentListItemViewModel {
    private let box: _AnyTorrentListItemViewModelBoxBase

    var base: Any { box.base }
    var name: AnyPublisher<String, Never> { box.name }
    var progress: AnyPublisher<Float, Never> { box.progress }
    var progressColor: AnyPublisher<UIColor, Never> { box.progressColor }
    var state: AnyPublisher<String, Never> { box.state }
    var speed: AnyPublisher<String, Never> { box.speed }
    var progressString: AnyPublisher<String, Never> { box.progressString }
    var ratioOrETA: AnyPublisher<String, Never> { box.ratioOrETA }

    init<VM: TorrentListItemViewModel>(_ viewModel: VM) {
        box = _AnyTorrentListItemViewModelBox(viewModel)
    }
}

extension TorrentListItemViewModel {
    func eraseToAny() -> AnyTorrentListItemViewModel {
        return AnyTorrentListItemViewModel(self)
    }
}
