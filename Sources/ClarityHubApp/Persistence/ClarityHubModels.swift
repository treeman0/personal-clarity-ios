import Foundation
import SwiftData

@Model
final class GoalRecord {
    var id: UUID = UUID()
    var title: String = ""
    var startingValue: Double = 0
    var currentValue: Double = 0
    var targetValue: Double = 0
    var directionRawValue: String = "increase"
    var dueDate: Date?
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String,
        startingValue: Double = 0,
        currentValue: Double,
        targetValue: Double,
        directionRawValue: String,
        dueDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startingValue = startingValue
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.directionRawValue = directionRawValue
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

@Model
final class HabitRecord {
    var id: UUID = UUID()
    var title: String = ""
    var weekdayMask: Int = 0
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String, weekdayMask: Int, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.weekdayMask = weekdayMask
        self.createdAt = createdAt
    }
}

@Model
final class HabitCheckInRecord {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var date: Date = Date()
    var state: String = "done"

    init(id: UUID = UUID(), habitID: UUID, date: Date, state: String = "done") {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.state = state
    }
}

@Model
final class ClarityListRecord {
    var id: UUID = UUID()
    var title: String = ""
    var kind: String = "todo"
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String, kind: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.kind = kind
        self.createdAt = createdAt
    }
}

@Model
final class TaskRecord {
    var id: UUID = UUID()
    var listID: UUID?
    var goalID: UUID?
    var projectID: UUID?
    var title: String = ""
    var status: String = "open"
    var dueDate: Date?
    var priority: Int = 0
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        listID: UUID? = nil,
        goalID: UUID? = nil,
        projectID: UUID? = nil,
        title: String,
        status: String = "open",
        dueDate: Date? = nil,
        priority: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.listID = listID
        self.goalID = goalID
        self.projectID = projectID
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.priority = priority
        self.createdAt = createdAt
    }
}

@Model
final class ProjectRecord {
    var id: UUID = UUID()
    var title: String = ""
    var desiredOutcome: String = ""
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String, desiredOutcome: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.desiredOutcome = desiredOutcome
        self.createdAt = createdAt
    }
}

@Model
final class NutritionDayRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var calories: Double = 0
    var proteinGrams: Double = 0
    var carbohydrateGrams: Double = 0
    var fatGrams: Double = 0
    var source: String = "Manual import"

    init(
        id: UUID = UUID(),
        date: Date,
        calories: Double,
        proteinGrams: Double,
        carbohydrateGrams: Double,
        fatGrams: Double,
        source: String
    ) {
        self.id = id
        self.date = date
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.source = source
    }
}

@Model
final class DailyReviewRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var wins: String = ""
    var friction: String = ""
    var nextFocus: String = ""

    init(id: UUID = UUID(), date: Date, wins: String, friction: String, nextFocus: String) {
        self.id = id
        self.date = date
        self.wins = wins
        self.friction = friction
        self.nextFocus = nextFocus
    }
}

@Model
final class WeeklyReviewRecord {
    var id: UUID = UUID()
    var weekStart: Date = Date()
    var keepDoing: String = ""
    var changeNextWeek: String = ""
    var focus: String = ""
    var commitments: String = ""

    init(
        id: UUID = UUID(),
        weekStart: Date,
        keepDoing: String,
        changeNextWeek: String,
        focus: String,
        commitments: String
    ) {
        self.id = id
        self.weekStart = weekStart
        self.keepDoing = keepDoing
        self.changeNextWeek = changeNextWeek
        self.focus = focus
        self.commitments = commitments
    }
}

@Model
final class AppPreferenceRecord {
    var id: UUID = UUID()
    var key: String = ""
    var value: String = ""

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}
