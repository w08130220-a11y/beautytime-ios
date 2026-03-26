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
    @State private var selectedRole: StaffRole = .designer

    var body: some View {
        NavigationStack {
            Form {
                Section("邀請資訊") {
                    TextField("電子信箱", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("職位", selection: $selectedRole) {
                        Text("負責人").tag(StaffRole.owner)
                        Text("店長").tag(StaffRole.manager)
                        Text("資深設計師").tag(StaffRole.seniorDesigner)
                        Text("設計師").tag(StaffRole.designer)
                        Text("助理").tag(StaffRole.assistant)
                    }
                }

                Section {
                    Text("邀請將發送至指定信箱，對方接受後即可加入您的團隊。")
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
                            await store.createStaffInvitation(email: email, role: selectedRole)
                            dismiss()
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(BTColor.primary)
                }
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
