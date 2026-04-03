import SwiftUI

// StaffInvitation model is defined in Models.swift

// MARK: - Invitations View

struct InvitationsView: View {
    @State private var invitations: [StaffInvitation] = []
    @State private var isLoading = false
    @State private var error: String?

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading && invitations.isEmpty {
                LoadingView()
            } else if invitations.isEmpty {
                EmptyStateView(
                    icon: "envelope.open",
                    title: "沒有邀請",
                    message: "目前沒有待處理的帳號綁定邀請"
                )
            } else {
                ScrollView {
                    VStack(spacing: BTSpacing.md) {
                        ForEach(invitations) { invitation in
                            InvitationCard(
                                invitation: invitation,
                                onAccept: { await acceptInvitation(invitation) },
                                onReject: { await rejectInvitation(invitation) }
                            )
                        }
                    }
                    .padding(BTSpacing.lg)
                }
            }
        }
        .background(BTColor.background)
        .navigationTitle("帳號綁定邀請")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadInvitations() }
        .refreshable { await loadInvitations() }
    }

    private func loadInvitations() async {
        isLoading = true
        do {
            invitations = try await api.get(path: APIEndpoints.Staff.myInvitations)
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("[Invitations] Failed to load: \(error)")
            #endif
        }
        isLoading = false
    }

    private func acceptInvitation(_ invitation: StaffInvitation) async {
        do {
            let _: StaffInvitation = try await api.patch(
                path: APIEndpoints.Staff.acceptInvitation(invitation.id),
                body: JSONBody(["accept": true] as [String: Any])
            )
            await loadInvitations()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func rejectInvitation(_ invitation: StaffInvitation) async {
        do {
            let _: StaffInvitation = try await api.patch(
                path: APIEndpoints.Staff.acceptInvitation(invitation.id),
                body: JSONBody(["accept": false] as [String: Any])
            )
            await loadInvitations()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Invitation Card

private struct InvitationCard: View {
    let invitation: StaffInvitation
    let onAccept: () async -> Void
    let onReject: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Provider Info
            HStack(spacing: BTSpacing.md) {
                Image(systemName: "storefront.fill")
                    .font(.title2)
                    .foregroundStyle(BTColor.primary)
                    .frame(width: 44, height: 44)
                    .background(BTColor.secondaryBackground)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    Text(invitation.provider?.name ?? "服務商")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(BTColor.textPrimary)

                    if let role = invitation.role {
                        BTBadge(text: roleDisplayName(role))
                    }
                }

                Spacer()

                if let status = invitation.status {
                    statusBadge(status)
                }
            }

            // Date
            if let createdAt = invitation.createdAt {
                Label(createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }

            // Action Buttons (only for pending)
            if invitation.status == .pending {
                HStack(spacing: BTSpacing.md) {
                    Button {
                        Task {
                            isProcessing = true
                            await onReject()
                            isProcessing = false
                        }
                    } label: {
                        Text("拒絕")
                            .btSecondaryButton()
                    }
                    .disabled(isProcessing)

                    Button {
                        Task {
                            isProcessing = true
                            await onAccept()
                            isProcessing = false
                        }
                    } label: {
                        Text("接受")
                            .btPrimaryButton(isDisabled: isProcessing)
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }

    private func roleDisplayName(_ role: StaffRole) -> String {
        switch role {
        case .owner: return "店主"
        case .manager: return "店長"
        case .seniorDesigner: return "資深設計師"
        case .designer: return "設計師"
        case .assistant: return "助理"
        }
    }

    private func statusBadge(_ status: InvitationStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .pending: return ("待處理", BTColor.warning)
            case .accepted: return ("已接受", BTColor.success)
            case .rejected: return ("已拒絕", BTColor.error)
            case .expired: return ("已過期", BTColor.textTertiary)
            }
        }()

        return Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, BTSpacing.xs)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        InvitationsView()
    }
}
