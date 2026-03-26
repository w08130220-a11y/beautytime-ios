import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AnalyticsManageStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                metricsCards
                revenueChart
                serviceRevenueChart
                returnRateSection
                customerMixSection
                unitPriceSection
            }
            .padding()
        }
        .navigationTitle("數據分析")
        .task {
            async let a: () = store.loadAnalytics()
            async let b: () = store.loadUnitPriceAnalytics()
            _ = await (a, b)
        }
        .refreshable {
            async let a: () = store.loadAnalytics()
            async let b: () = store.loadUnitPriceAnalytics()
            _ = await (a, b)
        }
    }

    // MARK: - Metrics Cards

    private var metricsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "總營收",
                value: Formatters.formatPrice(store.revenueData?.totalRevenue ?? 0),
                color: .green
            )
            MetricCard(
                title: "平均客單價",
                value: Formatters.formatPrice(store.revenueData?.averageOrderValue ?? 0),
                color: .blue
            )
            MetricCard(
                title: "預約數",
                value: "\(store.revenueData?.bookingCount ?? 0)",
                color: .purple
            )
        }
    }

    // MARK: - Revenue Chart

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月營收趨勢")
                .font(.headline)

            if let periodData = store.revenueData?.periodData, !periodData.isEmpty {
                Chart(periodData, id: \.period) { item in
                    BarMark(
                        x: .value("月份", item.period ?? ""),
                        y: .value("營收", item.revenue ?? 0)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("$\(Int(v))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("暫無數據", systemImage: "chart.bar.xaxis")
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Service Revenue Chart

    private var serviceRevenueChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("各服務營收")
                .font(.headline)

            if !store.serviceRevenue.isEmpty {
                Chart(store.serviceRevenue, id: \.serviceName) { item in
                    BarMark(
                        x: .value("營收", item.revenue ?? 0),
                        y: .value("服務", item.serviceName ?? "")
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: CGFloat(store.serviceRevenue.count) * 44)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("$\(Int(v))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("暫無數據", systemImage: "chart.bar")
                    .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Return Rate

    private var returnRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("回客率")
                .font(.headline)

            HStack(spacing: 24) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat((store.returnRate?.returnRate ?? 0) / 100))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(store.returnRate?.returnRate ?? 0))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("總顧客數")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(store.returnRate?.totalCustomers ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("回訪顧客")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(store.returnRate?.returningCustomers ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Customer Mix

    private var customerMixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("顧客組成")
                .font(.headline)

            VStack(spacing: 12) {
                CustomerMixBar(
                    label: "新客",
                    count: store.customerMix?.newCustomers ?? 0,
                    percentage: store.customerMix?.newPercentage ?? 0,
                    color: .blue
                )
                CustomerMixBar(
                    label: "回訪客",
                    count: store.customerMix?.returningCustomers ?? 0,
                    percentage: store.customerMix?.returningPercentage ?? 0,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    // MARK: - Unit Price Trend

    private var unitPriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("客單價趨勢")
                .font(.headline)

            if !store.unitPriceData.isEmpty {
                Chart(store.unitPriceData, id: \.period) { item in
                    LineMark(
                        x: .value("月份", item.period ?? ""),
                        y: .value("客單價", item.averageUnitPrice ?? 0)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    PointMark(
                        x: .value("月份", item.period ?? ""),
                        y: .value("客單價", item.averageUnitPrice ?? 0)
                    )
                    .foregroundStyle(Color.purple)
                }
                .frame(height: 200)
            } else {
                ContentUnavailableView("暫無數據", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(height: 120)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Customer Mix Bar

private struct CustomerMixBar: View {
    let label: String
    let count: Int
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(count) 人 (\(Int(percentage))%)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
            .environment(AnalyticsManageStore())
    }
}
