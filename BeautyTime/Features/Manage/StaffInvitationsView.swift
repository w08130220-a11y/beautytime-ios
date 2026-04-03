import SwiftUI

struct StaffInvitationsView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var showAddSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                if store.staffInvitations.isEmpty && !store.isLoading {
                    ContentUnavailableView(
                        "尚無邀請",
                        systemImage: "envelope.badge.person.crop",
                        description: Text("點擊右上角新增員工邀請")
                    )
                } else {
                    ForEach(store.staffInvitations) { invitation in
                        InvitationCard(invitation: invitation)
                    }
                }
            }
            .padding(BTSpacing.lg)
        }
        .btPageBackground()
        .navigationTitle("員工邀請")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增邀請", systemImage: "plus")
                }
                .tint(BTColor.primary)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddInvitationSheet(store: store)
        }
        .task {
            await store.loadStaffInvitations()
        }
        .refreshable {
            await store.loadStaffInvitations()
        }
        .alert("錯誤", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("確定") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
    }
}

// MARK: - Invitation Card

private struct InvitationCard: View {
    let invitation: StaffInvitation

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: "envelope.fill")
                .font(.title3)
                .foregroundStyle(BTColor.primary)
                .frame(width: 40, height: 40)
                .background(BTColor.primary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(invitation.email ?? invitation.staffEmail ?? "未知信箱")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(BTColor.textPrimary)

                if let role = invitation.role {
                    Text(role.displayName)
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }

                if let createdAt = invitation.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(BTColor.textTertiary)
                }
            }

            Spacer()

            if let status = invitation.status {
                BTBadge(
                    text: statusDisplayName(status),
                    color: statusColor(status)
                )
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }

    private func statusDisplayName(_ status: InvitationStatus) -> String {
        switch status {
        case .pending: return "待接受"
        case .accepted: return "已接受"
        case .rejected: return "已拒絕"
        case .expired: return "已過期"
        }
    }

    private func statusColor(_ status: InvitationStatus) -> Color {
        switch status {
        case .pending: return BTColor.warning
        case .accepted: return BTColor.success
        case .rejected: return BTColor.error
        case .expired: return BTColor.textTertiary
        }
    }
}

// MARK: - Add Invitation Sheet

private struct AddInvitationSheet: View {
    let store: StaffManageStore

    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var selectedStaff: StaffMember?

    var body: some View {
        NavigationStack {
            Form {
                Section("邀請資訊") {
                    TextField("對方的電子信箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("綁定員工", selection: $selectedStaff) {
                        Text("請選擇").tag(nil as StaffMember?)
                        ForEach(store.staff) { member in
                            Text("\(member.name) (\(member.role?.displayName ?? ""))").tag(member as StaffMember?)
                        }
                    }
                }

                Section {
                    Text("邀請將發送至指定信箱，對方接受後帳號將綁定至選擇的員工。")
                        .font(.caption)
                        .foregroundStyle(BTColor.textTertiary)
                }
            }
            .navigationTitle("新增邀請")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送出") {
                        Task {
                            guard let staff = selectedStaff else { return }
                            await store.createStaffInvitation(email: email, staffId: staff.id)
                            dismiss()
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || selectedStaff == nil)
                    .tint(BTColor.primary)
                }
            }
            .task {
                await store.loadStaff()
            }
        }
    }
}

#Preview {
    NavigationStack {
        StaffInvitationsView()
            .environment(StaffManageStore())
    }
}
