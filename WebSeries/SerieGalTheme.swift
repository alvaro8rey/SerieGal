import SwiftUI

extension Color {

    /// Azul corporativo SerieGal
    static let serieGalBlue = Color(
        red: 0.35,
        green: 0.60,
        blue: 1.00
    )

    /// Fondo principal (adaptativo real)
    static let serieGalBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.black
            : UIColor.systemBackground
        }
    )

    /// Texto principal (adaptativo real)
    static let serieGalText = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.label
        }
    )

    /// Texto secundario (adaptativo real)
    static let serieGalSecondary = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.lightGray
            : UIColor.secondaryLabel
        }
    )

    /// Superficie principal para bloques de contenido.
    static let serieGalSurface = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1)
            : UIColor(red: 0.95, green: 0.96, blue: 0.99, alpha: 1)
        }
    )

    /// Fondo de tarjetas estilo plataforma.
    static let serieGalCardBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.15, blue: 0.21, alpha: 1)
            : UIColor.white
        }
    )

    /// Texto terciario para metadatos y chips.
    static let serieGalTertiary = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.72, alpha: 1)
            : UIColor(white: 0.42, alpha: 1)
        }
    )

    /// Fondo del buscador (este estaba bien)
    static let serieGalSearchBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.15, alpha: 1)
            : UIColor(white: 0.95, alpha: 1)
        }
    )
}
