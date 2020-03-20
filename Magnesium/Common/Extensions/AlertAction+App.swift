extension AlertAction {
    static var ok: AlertAction {
        .init(title: L10n.ok, style: .default)
    }

    static var cancel: AlertAction {
        .init(title: L10n.cancel, style: .cancel)
    }
}
