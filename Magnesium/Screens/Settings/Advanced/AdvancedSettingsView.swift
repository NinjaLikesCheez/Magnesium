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
    @State private var isShowingResetConfirmation = false

    init(viewModel: VM) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section {
                Button(action: { self.isShowingResetConfirmation = true }, label: {
                    Text("Reset All Data")
                        .foregroundColor(.red)
                })
                    .actionSheet(isPresented: $isShowingResetConfirmation) {
                        ActionSheet(
                            title: Text("Are you sure you want to reset all data?"),
                            message: Text(
                                "This will reset all preferences to their default values and remove any servers."
                            ),
                            buttons: [
                                .destructive(Text("Remove All Data")),
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
