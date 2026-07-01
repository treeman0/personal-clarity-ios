import ClarityHubCore
import SwiftUI

struct ListsView: View {
    let tasks: [TaskItem]

    var body: some View {
        ScreenScaffold(title: "Lists", subtitle: "Todos, projects, and reusable lists without clutter.") {
            SectionPanel(title: "Priority queue") {
                ForEach(TaskPlanner.priorityQueue(tasks), id: \.title) { task in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                            Text("Priority \(task.priority)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

