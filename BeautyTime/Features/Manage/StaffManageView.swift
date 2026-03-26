import SwiftUI
import Kingfisher

struct StaffManageView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var showAddSheet = false
    @State private var editingStaff: StaffMember?

    var body: some View {
        List {
            ForEach(store.staff) { member in
                StaffRow(member: member)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingStaff = member
                    }
            }
            .onDelete(perform: deleteStaff)
        }
        .navigationTitle("員工管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增員工", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            StaffFormSheet(store: store, member: nil)
        }
        .sheet(item: $editingStaff) { member in
            StaffFormSheet(store: store, member: member)
        }
        .task {
            await store.loadStaff()
        }
    }

    private func deleteStaff(at offsets: IndexSet) {
        for index in offsets {
            let member = store.staff[index]
            Task {
                await store.deleteStaffMember(id: member.id)
            }
        }
    }
}

// MARK: - Staff Row

private struct StaffRow: View {
    let member: StaffMember

    var body: some View {
        HStack(spacing: 12) {
            if let photoUrl = member.photoUrl, let url = URL(string: photoUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.headline)
                    if let role = member.role {
                        Text(role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                if let title = member.title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let specialties = member.specialties, !specialties.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(specialties, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Circle()
                .fill(member.isActive == true ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Staff Form Sheet

private struct StaffFormSheet: View {
    let store: StaffManageStore
    let member: StaffMember?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var role: StaffRole = .designer
    @State private var title: String = ""
    @State private var specialtiesText: String = ""
    @State private var photoUrl: String = ""
    @State private var isActive: Bool = true

    private var isEditing: Bool { member != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("姓名", text: $name)
                    Picker("角色", selection: $role) {
                        ForEach([StaffRole.owner, .manager, .seniorDesigner, .designer, .assistant], id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    TextField("職稱", text: $title)
                }

                Section("專長（以逗號分隔）") {
                    TextField("例如：染髮, 燙髮, 剪髮", text: $specialtiesText)
                }

                Section("照片") {
                    TextField("照片 URL", text: $photoUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section {
                    Toggle("在職中", isOn: $isActive)
                }
            }
            .navigationTitle(isEditing ? "編輯員工" : "新增員工")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        Task {
                            await save()
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let member {
                    name = member.name
                    role = member.role ?? .designer
                    title = member.title ?? ""
                    specialtiesText = member.specialties?.joined(separator: ", ") ?? ""
                    photoUrl = member.photoUrl ?? ""
                    isActive = member.isActive ?? true
                }
            }
        }
    }

    private func save() async {
        let specialties = specialtiesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let body: [String: Any] = [
            "providerId": store.providerId,
            "name": name,
            "role": role.rawValue,
            "title": title,
            "specialties": specialties,
            "photoUrl": photoUrl,
            "isActive": isActive
        ]

        if let member {
            await store.updateStaffMember(id: member.id, body: body)
        } else {
            await store.createStaffMember(body)
        }
    }
}

#Preview {
    NavigationStack {
        StaffManageView()
            .environment(StaffManageStore())
    }
}
