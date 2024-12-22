import SwiftUI

struct NotificationListView: View {
    @State private var notifications = NotificationStore.fetchAll()

    var body: some View {
        List {
            ForEach(notifications.indices, id: \.self) { index in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notifications[index].body)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Scheduled at \(notifications[index].scheduledTime)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)

                if index < notifications.count - 1 { // Add a divider except after the last item
                    Divider()
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Scheduled notifications")
    }
}
