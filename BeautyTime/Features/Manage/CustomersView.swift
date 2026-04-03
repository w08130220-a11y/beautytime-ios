import SwiftUI

struct CustomersView: View {
    @Environment(CustomerManageStore.self) private var store

    @State private var searchText = ""
    @State private var expandedCustomerId: String?

    private var filteredCustomers: [CustomerWithNotes] {
        if searchText.isEmpty {
            return store.customers
        }
        return store.customers.filter { cwn in
            cwn.customer?.fullName?.localizedCaseInsensitiveContains(searchText) == true ||
            cwn.customer?.phone?.contains(searchText) == true
        }
    }

    var body: some View {
        List {
            if filteredCustomers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredCustomers) { cwn in
                    CustomerRow(
                        customerWithNotes: cwn,
                        isExpanded: expandedCustomerId == cwn.id,
                        onToggle: {
                            withAnimation {
                                expandedCustomerId = expandedCustomerId == cwn.id ? nil : cwn.id
                            }
                        },
                        store: store
                    )
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "搜尋顧客")
        .navigationTitle("顧客管理")
        .task {
            await store.loadCustomers()
        }
    }
}

// MARK: - Customer Row

private struct CustomerRow: View {
    let customerWithNotes: CustomerWithNotes
    let isExpanded: Bool
    let onToggle: () -> Void
    let store: ManageStore

    @State private var newNoteText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(customerWithNotes.customer?.fullName ?? "顧客")
                            .font(.headline)
                        HStack(spacing: 12) {
                            Label("\(customerWithNotes.bookingCount ?? 0) 次預約", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastVisit = customerWithNotes.lastVisit {
                                Label(Formatters.displayDateFormatter.string(from: lastVisit), systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                // Notes section
                if let notes = customerWithNotes.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("備註")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(notes) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "note.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.content ?? "")
                                        .font(.subheadline)
                                    if let date = note.createdAt {
                                        Text(Formatters.displayDateFormatter.string(from: date))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                if let noteId = note.id {
                                    Button {
                                        Task { await store.deleteCustomerNote(noteId: noteId) }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Add note form
                HStack {
                    TextField("新增備註", text: $newNoteText)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)

                    Button {
                        guard !newNoteText.isEmpty else { return }
                        let text = newNoteText
                        newNoteText = ""
                        Task {
                            await store.addCustomerNote(
                                customerId: customerWithNotes.id,
                                content: text
                            )
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(newNoteText.isEmpty)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CustomersView()
            .environment(ManageStore())
    }
}
