import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(Yard.self) private var yard
    @State private var settings = false
    @State private var edit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button { edit = true } label: {
                        ZStack(alignment: .bottomTrailing) {
                            FaceMark(profile: yard.profile, size: 120)
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .padding(7)
                                .background(Meadow.moss, in: Circle())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(yard.profile.name).font(Typeface.display(28))
                    Text(yard.profile.tagline).foregroundStyle(.secondary)
                    HStack {
                        chip(yard.rank.title)
                        chip("Day \((Calendar.current.dateComponents([.day], from: yard.profile.joinedAt, to: .now).day ?? 0) + 1)")
                    }

                    HStack {
                        metric("Track", yard.distanceLabel)
                        metric("Habits", "\(yard.totalCompletions)")
                        metric("Runs", "\(yard.runs.count)")
                    }

                    nav("Edit profile", "pencil") { edit = true }
                    NavigationLink { RunHistory() } label: { row("Run history", "figure.run") }
                    NavigationLink { AchievementBoard() } label: { row("Achievements", "seal") }
                    NavigationLink { JournalList() } label: { row("Journal", "book") }
                    NavigationLink { ArchiveBoard() } label: { row("Archive", "archivebox") }
                    NavigationLink { WebSheet(title: "Privacy Policy", url: Links.privacy) } label: { row("Privacy Policy", "lock.doc") }
                    NavigationLink { WebSheet(title: "Support", url: Links.support) } label: { row("Support", "questionmark.circle") }
                    NavigationLink { AboutView() } label: { row("About", "info.circle") }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { settings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $settings) { SettingsView() }
            .sheet(isPresented: $edit) { EditProfile() }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(Typeface.caption(12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Meadow.moss.opacity(0.15), in: Capsule())
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value).font(Typeface.title(18))
            Text(title).font(Typeface.caption(11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .henGlass(corner: 18)
    }

    private func nav(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { row(title, symbol) }.buttonStyle(.plain)
    }

    private func row(_ title: String, _ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(Meadow.moss).frame(width: 24)
            Text(title).font(Typeface.title(16))
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(14)
        .henGlass(corner: 18)
    }
}

struct EditProfile: View {
    @Environment(Yard.self) private var yard
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var tagline = ""
    @State private var goal = 3
    @State private var pick: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        FaceMark(profile: yard.profile, size: 88)
                        Spacer()
                    }
                    PhotosPicker("Choose photo", selection: $pick, matching: .images)
                    if !yard.profile.avatarPath.isEmpty {
                        Button("Remove photo", role: .destructive) {
                            var p = yard.profile
                            p.avatarPath = ""
                            yard.updateProfile(p)
                        }
                    }
                }
                TextField("Name", text: $name)
                TextField("Tagline", text: $tagline)
                Stepper("Daily habit goal: \(goal)", value: $goal, in: 1...12)
            }
            .navigationTitle("Edit profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var p = yard.profile
                        p.name = name
                        p.tagline = tagline
                        p.dailyGoal = goal
                        yard.updateProfile(p)
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = yard.profile.name
                tagline = yard.profile.tagline
                goal = yard.profile.dailyGoal
            }
            .onChange(of: pick) {
                Task { await loadPhoto() }
            }
        }
    }

    private func loadPhoto() async {
        guard let pick, let data = try? await pick.loadTransferable(type: Data.self) else { return }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("avatar-\(UUID().uuidString).jpg")
        try? data.write(to: url)
        var p = yard.profile
        p.avatarPath = url.path
        yard.updateProfile(p)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            HStack {
                HenImage(name: Artwork.logo, size: 56)
                VStack(alignment: .leading) {
                    Text("Crazy Hen Run").font(Typeface.title(20))
                    Text("Version \(Tuning.version)").foregroundStyle(.secondary)
                }
            }
            Text("A habit tracker that turns daily routines into distance. Offline, no account, no ads.")
            LabeledContent("Bundle", value: "com.crazyhenrun.crazyhenrungame")
        }
        .navigationTitle("About")
    }
}
