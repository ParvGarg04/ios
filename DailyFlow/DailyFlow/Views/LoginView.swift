import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp       = false
    @State private var name           = ""
    @State private var email          = ""
    @State private var password       = ""
    @State private var confirmPw      = ""
    @State private var showPassword   = false
    @State private var showForgot     = false
    @State private var forgotEmail    = ""
    @State private var forgotSent     = false
    @State private var localError:    String?

    var body: some View {
        ZStack {
            SoftBackgroundDecoration()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection

                    VStack(spacing: 20) {
                        formFields

                        if let error = localError ?? authViewModel.errorMessage {
                            errorBanner(error)
                        }

                        Button {
                            Task { await handleAction() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isSignUp ? "sparkles" : "heart.fill")
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(isLoading: authViewModel.isProcessing))
                        .disabled(authViewModel.isProcessing)

                        toggleButton

                        if !isSignUp {
                            Button("Forgot Password?") { showForgot = true }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
                }
            }
        }
        .sheet(isPresented: $showForgot) { forgotSheet }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 56)
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.gradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 20, y: 10)
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }
            VStack(spacing: 6) {
                Text("DailyFlow")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textDark)
                Text("Your daily wellness companion")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.bottom, 36)
    }

    // MARK: - Form Fields
    @ViewBuilder
    private var formFields: some View {
        if isSignUp {
            TextField("Full Name", text: $name)
                .textFieldStyle(DailyFlowTextFieldStyle())
                .autocorrectionDisabled()
                .transition(.opacity.combined(with: .move(edge: .top)))
        }

        TextField("Email address", text: $email)
            .textFieldStyle(DailyFlowTextFieldStyle())
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .autocorrectionDisabled()

        ZStack(alignment: .trailing) {
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .textFieldStyle(DailyFlowTextFieldStyle())

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.trailing, 16)
            }
        }

        if isSignUp {
            SecureField("Confirm Password", text: $confirmPw)
                .textFieldStyle(DailyFlowTextFieldStyle())
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.danger)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.danger)
        }
        .padding(14)
        .background(AppTheme.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.danger.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Toggle Button
    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                isSignUp.toggle()
                localError               = nil
                authViewModel.errorMessage = nil
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(AppTheme.secondaryText)
                Text(isSignUp ? "Sign In" : "Create Account")
                    .foregroundStyle(AppTheme.accent)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Forgot Sheet
    private var forgotSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    if forgotSent {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.success.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "envelope.badge.checkmark.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppTheme.success)
                            }
                            Text("Reset link sent!")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textDark)
                            Text("Check your inbox for password reset instructions.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                            Button("Done") { showForgot = false }
                                .buttonStyle(PrimaryButtonStyle())
                                .padding(.top, 8)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 18) {
                            Text("Enter your email and we'll send a reset link.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)

                            TextField("Email address", text: $forgotEmail)
                                .textFieldStyle(DailyFlowTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)

                            Button("Send Reset Link") {
                                Task {
                                    let ok = await authViewModel.resetPassword(email: forgotEmail)
                                    if ok { forgotSent = true }
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showForgot = false }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions
    private func handleAction() async {
        localError                  = nil
        authViewModel.errorMessage  = nil

        if isSignUp {
            guard !name.trimmed.isEmpty      else { localError = "Please enter your name.";       return }
            guard email.isValidEmail         else { localError = "Enter a valid email address.";  return }
            guard password.count >= 6        else { localError = "Password must be at least 6 characters."; return }
            guard password == confirmPw      else { localError = "Passwords don't match.";        return }
            await authViewModel.signUp(name: name.trimmed, email: email.trimmed, password: password)
        } else {
            guard !email.trimmed.isEmpty     else { localError = "Please enter your email.";      return }
            guard !password.isEmpty          else { localError = "Please enter your password.";   return }
            await authViewModel.signIn(email: email.trimmed, password: password)
        }
    }
}
