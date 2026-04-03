import SwiftUI

struct SelectServiceStep: View {
    var store: BookingFlowStore

    var body: some View {
        LazyVStack(spacing: 12) {
            if store.isLoading && store.services.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if store.services.isEmpty {
                ContentUnavailableView(
                    "目前沒有可用服務",
                    systemImage: "scissors",
                    description: Text("此店家尚未設定服務項目")
                )
            } else {
                ForEach(store.services) { service in
                    serviceRow(service)
                }
            }
        }
    }

    private func serviceRow(_ service: Service) -> some View {
        let isSelected = store.selectedService?.id == service.id

        return Button {
            store.selectedService = service
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    HStack(spacing: 16) {
                        if let duration = service.duration {
                            Label("\(duration) 分鐘", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let price = service.price {
                            Text(Formatters.formatPrice(price))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }

                    if let description = service.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        SelectServiceStep(store: store)
            .padding()
    }
}
