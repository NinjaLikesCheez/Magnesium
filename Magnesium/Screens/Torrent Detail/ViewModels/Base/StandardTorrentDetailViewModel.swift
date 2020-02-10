//
//  StandardTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-06.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import CoreServices
import Foundation
import LinkPresentation
import Preferences
import UIKit
import ViewModel

protocol StandardTorrentDetailViewModelImplementation {
    associatedtype Torrent: StandardTorrent
    associatedtype Label: StandardLabel
    associatedtype File: StandardTorrentFile
    func refresh() -> AnyPublisher<Void, Error>
    func updateFiles(_ torrent: Torrent) -> AnyPublisher<[File], Error>
    func pause(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func resume(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func remove(_ torrent: Torrent, removeData: Bool) -> AnyPublisher<Void, Error>
    func recheck(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func setLabel(_ label: Label, for torrent: Torrent) -> AnyPublisher<Void, Error>
}

// swiftlint:disable:next line_length
final class StandardTorrentDetailViewModel<Implementation: StandardTorrentDetailViewModelImplementation>: ViewModel, EventEmitter {
    typealias Torrent = Implementation.Torrent
    typealias Label = Implementation.Label
    typealias File = Implementation.File

    private let implementation: Implementation
    private let preferences: Preferences
    private let torrent: CurrentValueSubject<Torrent, Never>
    private let labels: CurrentValueSubject<[Label], Never>
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    private var observers = [AnyCancellable]()
    private var autoRefreshTimer: Timer?
    private var timerIntervalObserver: AnyCancellable?
    let state: TorrentDetailViewState

    let files: ValueMapper<Int, File> = {
        ValueMapper(filter: Just {
            $0.sorted {
                let result = $0.value.name.compare(
                    $1.value.name,
                    options: [.numeric, .caseInsensitive]
                )
                switch result {
                case .orderedSame:
                    return $0.value.index < $1.value.index
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                }
            }
        }.eraseToAnyPublisher())
    }()

    var events: AnyPublisher<TorrentDetailEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(
        implementation: Implementation,
        torrent: CurrentValueSubject<Torrent, Never>,
        labels: CurrentValueSubject<[Label], Never>,
        preferences: Preferences
    ) {
        self.implementation = implementation
        self.torrent = torrent
        self.labels = labels
        self.preferences = preferences

        let sections = torrent
            .combineLatest(files.values)
            .map { torrentValue, files in
                Self.createSections(
                    subject: torrent,
                    torrent: torrentValue,
                    files: files
                )
            }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()
        state = TorrentDetailViewState(sections: sections, isLoading: isLoadingSubject.eraseToAnyPublisher())

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    private static func createSections(
        subject: CurrentValueSubject<Torrent, Never>,
        torrent: Torrent,
        files: [CurrentValueSubject<File, Never>]
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(TorrentDetailSection(type: .header, items: [
            .header(AnyViewModel(StandardTorrentDetailHeaderViewModel(subject: subject))),
        ]))
        let ui = subject.ui()
        sections.append(TorrentDetailSection(type: .info, items: [
            .info("Size", ui.map { ByteFormatter.string(fromByteCount: $0.size) }.eraseToAnyPublisher()),
            .info("Download Speed", ui
                .map { "\(ByteFormatter.string(fromByteCount: $0.downloadRate))/s" }
                .eraseToAnyPublisher()),
            .info("Upload Speed", ui
                .map { "\(ByteFormatter.string(fromByteCount: $0.uploadRate))/s" }
                .eraseToAnyPublisher()),
            .info("Downloaded", ui.map { ByteFormatter.string(fromByteCount: $0.downloaded) }.eraseToAnyPublisher()),
            .info("Uploaded", ui.map { ByteFormatter.string(fromByteCount: $0.uploaded) }.eraseToAnyPublisher()),
            .info("ETA", ui.map(\.etaString).eraseToAnyPublisher()),
            .info("Ratio", ui.map { $0.ratioString(precision: 3) }.eraseToAnyPublisher()),
            .info("Peers", ui.map { "\($0.peers) (\($0.totalPeers))" }.eraseToAnyPublisher()),
            .info("Seeds", ui.map { "\($0.seeds) (\($0.totalSeeds))" }.eraseToAnyPublisher()),
        ]))

        if !torrent.trackerStrings.isEmpty {
            sections.append(TorrentDetailSection(type: .trackers, items: torrent.trackerStrings.map { .tracker($0) }))
        }

        if !files.isEmpty {
            sections.append(TorrentDetailSection(type: .files, items: files.map {
                .file(AnyViewModel(StandardTorrentDetailFileViewModel(subject: $0)))
            }))
        }

        return sections
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(AlertAction(title: "OK", style: .default))
        eventSubject.send(.alert(alert, source: nil))
    }

    private func pause() {
        implementation.pause(torrent.value)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Pause", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func resume() {
        implementation.resume(torrent.value)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Resume", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func remove(removeData: Bool) {
        implementation.remove(torrent.value, removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.eventSubject.send(.complete)
                case let .failure(error):
                    self?.showError(title: "Failed to Remove", message: error.localizedDescription)
                }
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    // internal for testing
    func recheck() {
        implementation.recheck(torrent.value)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Recheck", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    // internal for testing
    func setLabel(_ label: Label) {
        implementation.setLabel(label, for: torrent.value)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Set Label", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func presentRemove(from source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.addAction(AlertAction(title: "Keep Data", style: .default) {
            self.remove(removeData: false)
        })
        alert.addAction(AlertAction(title: "Remove Data", style: .destructive) {
            self.remove(removeData: true)
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    // internal for testing
    func presentLabelSelection(from source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        for label in labels.value {
            alert.addAction(AlertAction(title: label.displayName, style: .default) {
                self.setLabel(label)
            })
        }
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    // MARK: Handle

    func handle(_ event: TorrentDetailViewEvent) {
        switch event {
        case .appear:
            handleAppear()
        case .disappear:
            handleDisappear()
        case .refresh:
            handleRefresh()
        case let .moreOptions(source):
            handleMoreOptions(from: source)
        case .pause:
            pause()
        case .resume:
            resume()
        case let .remove(source):
            presentRemove(from: source)
        }
    }

    private func handleAppear() {
        if let timer = autoRefreshTimer, timer.isValid {
            return
        }

        timerIntervalObserver = preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
    }

    private func handleDisappear() {
        autoRefreshTimer?.invalidate()
        timerIntervalObserver?.cancel()
    }

    private func handleRefresh() {
        guard !isLoadingSubject.value else { return }
        isLoadingSubject.send(true)
        implementation.refresh()
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let strongSelf = self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
                return strongSelf.refreshFiles()
            }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoadingSubject.send(false)
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func refreshFiles() -> AnyPublisher<Void, Error> {
        return implementation.updateFiles(torrent.value)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.index, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func handleMoreOptions(from source: PopoverSource) {
        var activities = [UIActivity]()

        if !labels.value.isEmpty {
            activities.append(SetLabelActivity {
                self.presentLabelSelection(from: source)
            })
        }

        activities.append(RecheckActivity {
            self.recheck()
        })

        eventSubject.send(.activities(activities, metadata: LPLinkMetadata(torrent: torrent.value)))
    }

    // MARK: Auto Refresh

    private func configureAutoRefreshTimer(interval: TimeInterval?) {
        autoRefreshTimer?.invalidate()
        guard let interval = interval, interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.refreshTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefreshTimer = timer
    }

    private func refreshTimerFired(_ timer: Timer) {
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }
}
