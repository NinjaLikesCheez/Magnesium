//
//  AnyTorrentDetailHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
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

private class _AnyTorrentDetailHeaderViewModelBoxBase: TorrentDetailHeaderViewModel {
    var base: Any { _abstract() }
    var name: AnyPublisher<String, Never> { _abstract() }
    var isActive: AnyPublisher<Bool, Never> { _abstract() }
    var progress: AnyPublisher<Float, Never> { _abstract() }
    var progressColor: AnyPublisher<UIColor, Never> { _abstract() }
    var status: AnyPublisher<String, Never> { _abstract() }

    static func == (
        lhs: _AnyTorrentDetailHeaderViewModelBoxBase,
        rhs: _AnyTorrentDetailHeaderViewModelBoxBase
    ) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func hash(into hasher: inout Hasher) { _abstract() }
    func isEqual(to other: _AnyTorrentDetailHeaderViewModelBoxBase) -> Bool { _abstract() }
}

private final class _AnyTorrentDetailHeaderViewModelBox<
    Base: TorrentDetailHeaderViewModel
>: _AnyTorrentDetailHeaderViewModelBoxBase {
    private let _base: Base

    override var base: Any { _base }
    override var name: AnyPublisher<String, Never> { _base.name }
    override var isActive: AnyPublisher<Bool, Never> { _base.isActive }
    override var progress: AnyPublisher<Float, Never> { _base.progress }
    override var progressColor: AnyPublisher<UIColor, Never> { _base.progressColor }
    override var status: AnyPublisher<String, Never> { _base.status }

    init(_ base: Base) {
        _base = base
    }

    override func hash(into hasher: inout Hasher) {
        _base.hash(into: &hasher)
    }

    override func isEqual(to other: _AnyTorrentDetailHeaderViewModelBoxBase) -> Bool {
        guard let other = other as? _AnyTorrentDetailHeaderViewModelBox<Base> else { return false }
        return _base == other._base
    }
}

struct AnyTorrentDetailHeaderViewModel: TorrentDetailHeaderViewModel {
    private let box: _AnyTorrentDetailHeaderViewModelBoxBase

    var base: Any { box.base }
    var name: AnyPublisher<String, Never> { box.name }
    var isActive: AnyPublisher<Bool, Never> { box.isActive }
    var progress: AnyPublisher<Float, Never> { box.progress }
    var progressColor: AnyPublisher<UIColor, Never> { box.progressColor }
    var status: AnyPublisher<String, Never> { box.status }

    init<VM: TorrentDetailHeaderViewModel>(_ viewModel: VM) {
        box = _AnyTorrentDetailHeaderViewModelBox(viewModel)
    }
}

extension TorrentDetailHeaderViewModel {
    func eraseToAny() -> AnyTorrentDetailHeaderViewModel {
        return AnyTorrentDetailHeaderViewModel(self)
    }
}
