pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ─────────────────────────────────────────────
    // Dracula Palette
    // ─────────────────────────────────────────────

    readonly property string background: "#282A36"
    readonly property string surface: "#282A36"
    readonly property string surface_dim: "#1E1F29"
    readonly property string surface_variant: "#44475A"

    readonly property string surface_container_lowest: "#1E1F29"
    readonly property string surface_container_low: "#21222C"
    readonly property string surface_container: "#282A36"
    readonly property string surface_container_high: "#2B2D3A"
    readonly property string surface_container_highest: "#343746"

    readonly property string surface_bright: "#3B3F51"
    readonly property string surface_tint: "#BD93F9"

    readonly property string foreground: "#F8F8F2"
    readonly property string on_background: "#F8F8F2"
    readonly property string on_surface: "#F8F8F2"
    readonly property string on_surface_variant: "#6272A4"

    readonly property string outline: "#44475A"
    readonly property string outline_variant: "#2C2E3A"

    readonly property string scrim: "#000000"
    readonly property string shadow: "#000000"

    // ── Semantic colors ───────────────────────────

    readonly property string primary: "#BD93F9"
    readonly property string primary_container: "#44475A"
    readonly property string on_primary: "#282A36"
    readonly property string on_primary_container: "#F8F8F2"

    readonly property string secondary: "#6272A4"
    readonly property string secondary_container: "#44475A"
    readonly property string on_secondary: "#F8F8F2"
    readonly property string on_secondary_container: "#F8F8F2"

    readonly property string tertiary: "#FF79C6"
    readonly property string tertiary_container: "#5C3A52"
    readonly property string on_tertiary: "#282A36"
    readonly property string on_tertiary_container: "#F8F8F2"

    readonly property string error: "#FF5555"
    readonly property string error_container: "#5A1F1F"
    readonly property string on_error: "#F8F8F2"
    readonly property string on_error_container: "#FFB4AB"

    // ── Accent / extras ───────────────────────────

    readonly property string source_color: "#BD93F9"
    readonly property string inverse_surface: "#F8F8F2"
    readonly property string inverse_on_surface: "#282A36"
    readonly property string inverse_primary: "#6272A4"

    readonly property string surface_variant_alt: "#44475A"
}
