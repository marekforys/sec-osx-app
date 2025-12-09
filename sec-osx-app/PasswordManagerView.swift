//
//  PasswordManagerView.swift
//  sec-osx-app
//
//  View for managing saved passwords
//

import SwiftUI
import Security

struct PasswordManagerView: View {
    @StateObject private var passwordManager = PasswordManager.shared
    @State private var showingAddPassword = false
    @State private var searchText = ""

    var filteredPasswords: [PasswordManager.PasswordItem] {
        if searchText.isEmpty {
            return passwordManager.passwords
        } else {
            return passwordManager.passwords.filter {
                $0.service.localizedCaseInsensitiveContains(searchText) ||
                $0.account.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding()

            // Password list
            if filteredPasswords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No passwords saved yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Click the + button to add your first password")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredPasswords) { password in
                        PasswordRow(password: password)
                            .contextMenu {
                                Button(action: {
                                    copyToClipboard(password.password)
                                }) {
                                    Label("Copy Password", systemImage: "doc.on.doc")
                                }
                                Button(action: {
                                    copyToClipboard(password.account)
                                }) {
                                    Label("Copy Username", systemImage: "person.crop.circle")
                                }
                                Divider()
                                Button(role: .destructive, action: {
                                    passwordManager.deletePassword(password.id)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Password Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddPassword = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPassword) {
            AddPasswordView()
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct PasswordRow: View {
    let password: PasswordManager.PasswordItem
    @State private var isPasswordVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(password.service)
                    .font(.headline)
                Spacer()
                Text(password.account)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                if isPasswordVisible {
                    Text(password.password)
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text(String(repeating: "•", count: min(12, password.password.count)))
                        .font(.system(.body, design: .monospaced))
                }

                Spacer()

                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(password.password, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            if !password.notes.isEmpty {
                Text(password.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SearchBar: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = "Search passwords..."
        searchField.delegate = context.coordinator
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        let parent: SearchBar

        init(_ parent: SearchBar) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            if let searchField = notification.object as? NSSearchField {
                parent.text = searchField.stringValue
            }
        }
    }
}

struct AddPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = ""
    @State private var account = ""
    @State private var password = ""
    @State private var notes = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Service (e.g., Google)", text: $service)
                TextField("Username/Email", text: $account)

                HStack {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }

                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        password = generateStrongPassword()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Generate strong password")
                }

                TextField("Notes (optional)", text: $notes)

                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Strength: \(passwordStrength)")
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor)

                        PasswordStrengthIndicator(strength: passwordStrengthValue)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(minWidth: 400, minHeight: 300)
            .navigationTitle("Add Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        PasswordManager.shared.addPassword(
                            service: service,
                            account: account,
                            password: password,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(service.isEmpty || account.isEmpty || password.isEmpty)
                }
            }
        }
    }

    private var passwordStrength: String {
        let strength = passwordStrengthValue
        switch strength {
        case 0..<0.25: return "Weak"
        case 0.25..<0.5: return "Fair"
        case 0.5..<0.75: return "Good"
        default: return "Strong"
        }
    }

    private var passwordStrengthColor: Color {
        let strength = passwordStrengthValue
        switch strength {
        case 0..<0.25: return .red
        case 0.25..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        default: return .green
        }
    }

    private var passwordStrengthValue: Double {
        var strength: Double = 0

        // Length check
        if password.count >= 12 { strength += 0.3 }
        else if password.count >= 8 { strength += 0.2 }
        else if password.count >= 6 { strength += 0.1 }

        // Complexity checks
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let specialCharacters = "!@#$%^&*()_+-={}[]|:;\"'<>,.?~`/\\"
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: specialCharacters)) != nil

        if hasUppercase { strength += 0.15 }
        if hasLowercase { strength += 0.15 }
        if hasNumbers { strength += 0.15 }
        if hasSpecial { strength += 0.25 }

        return min(max(strength, 0), 1)
    }

    private func generateStrongPassword() -> String {
        let length = 16
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let special = "!@#$%^&*()_+-=[]{}|;:,.<>?"

        var password = ""
        var remainingLength = length

        // Ensure at least one character from each set
        password.append(uppercase.randomElement()!)
        password.append(lowercase.randomElement()!)
        password.append(numbers.randomElement()!)
        password.append(special.randomElement()!)
        remainingLength = length - 4

        // Fill the rest with random characters
        let allChars = uppercase + lowercase + numbers + special
        for _ in 0..<remainingLength {
            password.append(allChars.randomElement()!)
        }

        // Shuffle the password to avoid predictable patterns
        return String(password.shuffled())
    }
}

struct PasswordStrengthIndicator: View {
    let strength: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 4)
                    .opacity(0.1)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(width: min(CGFloat(strength) * geometry.size.width, geometry.size.width), height: 4)
                    .foregroundColor(strengthColor)
                    .animation(.linear, value: strength)
            }
            .cornerRadius(2)
        }
        .frame(height: 4)
    }

    private var strengthColor: Color {
        switch strength {
        case 0..<0.25: return .red
        case 0.25..<0.5: return .orange
        case 0.5..<0.75: return .yellow
        default: return .green
        }
    }
}
