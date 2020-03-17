import MVVMModels

extension AlertAction {
    static var ok: AlertAction {
        return AlertAction(title: L10n.ok, style: .default)
    }

    static var cancel: AlertAction {
        return AlertAction(title: L10n.cancel, style: .cancel)
    }
}
