import CommonModels

extension AlertAction {
    static var ok: AlertAction {
        .init(title: L10n.Action.ok, style: .default)
    }

    static var cancel: AlertAction {
        .init(title: L10n.Action.cancel, style: .cancel)
    }
}
