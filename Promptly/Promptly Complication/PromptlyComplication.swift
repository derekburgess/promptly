//
//  PromptlyComplication.swift
//  Promptly - Watch Assistant
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct PromptlyComplicationEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Image("promptlyImage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
    }
}

@main
struct PromptlyComplication: Widget {
    let kind: String = "PromptlyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PromptlyComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Promptly")
        .description("Tap to launch the Promptly app")
        .supportedFamilies([.accessoryCircular])
    }
}
