import ViewModel

struct StaticViewModel<ViewEvent, ViewRepresentation>: ViewModel {
    let view: ViewRepresentation

    init(view: ViewRepresentation, type: ViewEvent.Type) {
        self.view = view
    }

    func receive(_ event: ViewEvent) {}
}
