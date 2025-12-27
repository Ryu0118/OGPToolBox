/// Twitter card types as defined by Twitter's card specification.
public enum TwitterCardType: String, Sendable, Equatable, Codable {
    /// A card with a small square image.
    case summary

    /// A card with a large, prominently-featured image.
    case summaryLargeImage = "summary_large_image"

    /// A card with a playable media player.
    case player

    /// A card for mobile app downloads.
    case app
}
