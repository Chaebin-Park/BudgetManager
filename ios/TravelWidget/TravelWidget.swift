//
//  TravelWidget.swift
//  TravelWidget
//
//  Created by 박채빈 on 5/29/24.
//

import WidgetKit
import SwiftUI

struct Travel: Identifiable, Decodable {
    let id: UUID
    let title: String
    let totalFunds: Double
    let remainingFunds: Double
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), travelData: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, travelData: [])
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Fetch data from Flutter database
        let travelData = fetchTravelData()

        // Generate a timeline consisting of entries.
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, travelData: travelData)
        entries.append(entry)

        // Update timeline every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        return timeline
    }
    
    func fetchTravelData() -> [Travel] {
        // Fetch data from Flutter using UserDefaults or AppGroup
        if let userDefaults = UserDefaults(suiteName: "group.com.cbpark.budget_manager") {
            if let data = userDefaults.data(forKey: "travelData") {
                if let travelData = try? JSONDecoder().decode([Travel].self, from: data) {
                    print("apple")
                    print(travelData)
                    return travelData
                }
            }
        }
        return []
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let travelData: [Travel]
}

struct TravelWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            ForEach(entry.travelData) { travel in
                VStack(alignment: .leading) {
                    Text(travel.title)
                        .font(.headline)
                    Text("Total: \(travel.totalFunds, specifier: "%.2f")")
                        .font(.subheadline)
                    Text("Remaining: \(travel.remainingFunds, specifier: "%.2f")")
                        .font(.subheadline)
                }
                Divider()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.5))
        .containerBackground(.white, for: .widget)
    }
}

struct TravelWidget: Widget {
    let kind: String = "TravelWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TravelWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Travel Widget")
        .description("Displays travel budgets and balances.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
