import Combine

struct RefreshIntervalViewValues {
    var options: [OptionItem]
}

extension RefreshIntervalViewValues {
    struct OptionItem {
        var title: String
        var isSelected: UIPublisher<Bool>
    }
}
