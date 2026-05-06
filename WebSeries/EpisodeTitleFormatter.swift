import Foundation

func formattedEpisodeTitle(
    serieTitle: String,
    episodeTitle: String,
    index: Int
) -> String {

    var title = episodeTitle

    // Quitar nombre de la serie si aparece al inicio
    if title.lowercased().hasPrefix(serieTitle.lowercased()) {
        title = String(title.dropFirst(serieTitle.count))
            .trimmingCharacters(in: .whitespaces)
    }

    // Quitar números tipo "001 -", "01 -", "1 -"
    title = title.replacingOccurrences(
        of: #"^\d+\s*-\s*"#,
        with: "",
        options: .regularExpression
    )

    return "\(index). \(title)"
}
