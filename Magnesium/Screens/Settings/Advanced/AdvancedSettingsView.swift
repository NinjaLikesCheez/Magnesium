//
//  AdvancedSettingsView.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-31.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import SwiftUI
import ViewModel

struct AdvancedSettingsView<VM: ViewModel>: View
    where VM.ViewEvent == AdvancedSettingsViewEvent, VM.ViewState == AdvancedSettingsViewState {
    private let viewModel: VM
    @State private var isShowingClearDocumentsConfirmation = false
    @State private var isShowingClearTempDirectoryConfirmation = false
    @State private var isShowingClearCacheConfirmation = false
    @State private var isShowingClearLaunchScreenCacheConfirmation = false
    @State private var isShowingResetConfirmation = false

    init(viewModel: VM) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section {
                Button(
                    action: { self.isShowingClearDocumentsConfirmation = true },
                    label: { Text("Clear Documents").foregroundColor(.accentColor) }
                )
                .actionSheet(isPresented: $isShowingClearDocumentsConfirmation) {
                    ActionSheet(
                        title: Text("This will delete all files in the Documents directory."),
                        buttons: [
                            .destructive(Text("Clear Documents")) {
                                self.viewModel.handle(.clearDocumentsSelected)
                            },
                            .cancel(),
                        ]
                    )
                }

                Button(
                    action: { self.isShowingClearTempDirectoryConfirmation = true },
                    label: { Text("Clear Temporary Files").foregroundColor(.accentColor) }
                )
                .actionSheet(isPresented: $isShowingClearTempDirectoryConfirmation) {
                    ActionSheet(
                        title: Text("This will delete all files in the temporary files directory."),
                        buttons: [
                            .destructive(Text("Clear Files")) {
                                self.viewModel.handle(.clearTempDirectorySelected)
                            },
                            .cancel(),
                        ]
                    )
                }

                Button(
                    action: { self.isShowingClearCacheConfirmation = true },
                    label: { Text("Clear Caches").foregroundColor(.accentColor) }
                )
                .actionSheet(isPresented: $isShowingClearCacheConfirmation) {
                    ActionSheet(
                        title: Text("This will remove all files in the Caches directory."),
                        buttons: [
                            .destructive(Text("Clear Caches")) {
                                self.viewModel.handle(.clearCacheSelected)
                            },
                            .cancel(),
                        ]
                    )
                }

                Button(
                    action: { self.isShowingClearLaunchScreenCacheConfirmation = true },
                    label: { Text("Reset Launch Screen Cache").foregroundColor(.accentColor) }
                )
                .actionSheet(isPresented: $isShowingClearLaunchScreenCacheConfirmation) {
                    ActionSheet(
                        title: Text("This will delete all cached launch screen images."),
                        buttons: [
                            .destructive(Text("Clear Cache")) {
                                self.viewModel.handle(.clearLaunchScreenCacheSelected)
                            },
                            .cancel(),
                        ]
                    )
                }

                Button(
                    action: { self.isShowingResetConfirmation = true },
                    label: { Text("Reset All Data").foregroundColor(.red) }
                )
                .actionSheet(isPresented: $isShowingResetConfirmation) {
                    ActionSheet(
                        title: Text("Are you sure you want to reset all data?"),
                        message: Text(
                            "This will delete any application data and reset all preferences to their default values."
                        ),
                        buttons: [
                            .destructive(Text("Remove All Data")) {
                                self.viewModel.handle(.resetDataSelected)
                            },
                            .cancel(),
                        ]
                    )
                }
            }
        }
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular) // hack to get inset grouped style
        .navigationBarTitle("Advanced Settings")
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsView(viewModel: PreviewViewModel(state: AdvancedSettingsViewState()))
    }
}
