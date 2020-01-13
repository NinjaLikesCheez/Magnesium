/// Styles that can be used for presentations.
public enum PresentationStyle {
    case automatic
    case fullScreen
    case pageSheet
    case formSheet
    case currentContext
    case custom
    case overFullScreen
    case overCurrentContext
    case popover(source: PopoverSource)
    case none
}
