import SwiftUI

// MARK: - App Theme
enum AppTheme {
    static let accent       = Color("AccentColor")
    static let background   = Color("BackgroundColor")
    static let cardBackground = Color("CardBackground")
    static let secondaryText  = Color("SecondaryText")
    static let success      = Color("SuccessColor")
    static let warning      = Color("WarningColor")
    static let danger       = Color("DangerColor")

    static let lavender     = Color("Lavender")
    static let peach        = Color("Peach")
    static let softBorder   = Color("SoftBorder")
    static let textDark     = Color("TextDark")

    static let cornerRadius: CGFloat       = 20
    static let smallCornerRadius: CGFloat  = 14
    static let pillRadius: CGFloat         = 999
    static let padding: CGFloat            = 18

    static let gradient = LinearGradient(
        colors: [Color("GradientStart"), Color("GradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softGradient = LinearGradient(
        colors: [Color("GradientStart").opacity(0.85), Color("Peach").opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardShadow = Color(red: 0.85, green: 0.65, blue: 0.75).opacity(0.18)
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    var elevated: Bool = false
    @Environment(\.colorScheme) var scheme

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.padding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(AppTheme.softBorder.opacity(scheme == .dark ? 0.3 : 0.9), lineWidth: 1)
            )
            .shadow(
                color: scheme == .dark ? .clear : AppTheme.cardShadow,
                radius: elevated ? 18 : 10,
                x: 0,
                y: elevated ? 8 : 4
            )
    }
}

extension View {
    func cardStyle(elevated: Bool = false) -> some View {
        modifier(CardModifier(elevated: elevated))
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.85)
            }
            configuration.label
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            Capsule(style: .continuous)
                .fill(
                    isDisabled
                    ? AnyShapeStyle(Color.gray.opacity(0.35))
                    : AnyShapeStyle(AppTheme.gradient)
                )
        )
        .shadow(
            color: isDisabled ? .clear : AppTheme.accent.opacity(0.35),
            radius: 12, x: 0, y: 5
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .opacity(isLoading ? 0.85 : 1)
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .stroke(AppTheme.softBorder, lineWidth: 1.5)
                    .background(Capsule(style: .continuous).fill(AppTheme.accent.opacity(0.06)))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.danger)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

// MARK: - TextField Style
struct DailyFlowTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius, style: .continuous)
                    .stroke(AppTheme.softBorder, lineWidth: 1.5)
            )
    }
}

// MARK: - ThemeManager
final class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
}

// MARK: - Toast Banner
struct ToastBanner: View {
    let message: String
    let isSuccess: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isSuccess ? AppTheme.success : AppTheme.danger)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textDark)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.softBorder, lineWidth: 1)
                )
                .shadow(color: AppTheme.cardShadow, radius: 14, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Decorative Background
struct SoftBackgroundDecoration: View {
    var body: some View {
        ZStack {
            AppTheme.background
            Circle()
                .fill(AppTheme.lavender.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -120, y: -200)
            Circle()
                .fill(AppTheme.peach.opacity(0.22))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 140, y: -80)
            Circle()
                .fill(AppTheme.accent.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .offset(x: 80, y: 300)
        }
        .ignoresSafeArea()
    }
}
