//
//  AnyTorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
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

private class _AnyTorrentDetailFileViewModelBoxBase: TorrentDetailFileViewModel {
    var base: Any { _abstract() }
    var name: String { _abstract() }
    var detail: AnyPublisher<String, Never> { _abstract() }
    var progress: AnyPublisher<String, Never> { _abstract() }

    static func == (
        lhs: _AnyTorrentDetailFileViewModelBoxBase,
        rhs: _AnyTorrentDetailFileViewModelBoxBase
    ) -> Bool {
        return lhs.isEqual(to: rhs)
    }

    func hash(into hasher: inout Hasher) { _abstract() }
    func isEqual(to other: _AnyTorrentDetailFileViewModelBoxBase) -> Bool { _abstract() }
}

private final class _AnyTorrentDetailFileViewModelBox<
    Base: TorrentDetailFileViewModel
>: _AnyTorrentDetailFileViewModelBoxBase {
    private let _base: Base

    override var base: Any { _base }
    override var name: String { _base.name }
    override var detail: AnyPublisher<String, Never> { _base.detail }
    override var progress: AnyPublisher<String, Never> { _base.progress }

    init(_ base: Base) {
        _base = base
    }

    override func hash(into hasher: inout Hasher) {
        _base.hash(into: &hasher)
    }

    override func isEqual(to other: _AnyTorrentDetailFileViewModelBoxBase) -> Bool {
        guard let other = other as? _AnyTorrentDetailFileViewModelBox<Base> else { return false }
        return _base == other._base
    }
}

struct AnyTorrentDetailFileViewModel: TorrentDetailFileViewModel {
    private let box: _AnyTorrentDetailFileViewModelBoxBase

    var base: Any { box.base }
    var name: String { box.name }
    var detail: AnyPublisher<String, Never> { box.detail }
    var progress: AnyPublisher<String, Never> { box.progress }

    init<VM: TorrentDetailFileViewModel>(_ viewModel: VM) {
        box = _AnyTorrentDetailFileViewModelBox(viewModel)
    }
}

extension TorrentDetailFileViewModel {
    func eraseToAny() -> AnyTorrentDetailFileViewModel {
        return AnyTorrentDetailFileViewModel(self)
    }
}
