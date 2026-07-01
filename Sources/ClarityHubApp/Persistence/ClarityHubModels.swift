import Foundation
import SwiftData

@Model
final class GoalRecord {
    var id: UUID
    var title: String
    var currentValue: Double
    var targetValue: Double
    var directionRawValue: String
    var dueDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        currentValue: Double,
        targetValue: Double,
        directionRawValue: String,
        dueDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.directionRawValue = directionRawValue
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

@Model
final class HabitRecord {
    var id: UUID
    var title: String
    var weekdayMask: Int
    var createdAt: Date

    init(id: UUID = UUID(), title: String, weekdayMask: Int, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.weekdayMask = weekdayMask
        self.createdAt = createdAt
    }
}

@Model
final class HabitCheckInRecord {
    var id: UUID
    var habitID: UUID
    var date: Date
    var state: String

    init(id: UUID = UUID(), habitID: UUID, date: Date, state: String = "done") {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.state = state
    }
}

@Model
final class ClarityListRecord {
    var id: UUID
    var title: String
    var kind: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, kind: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.kind = kind
        self.createdAt = createdAt
    }
}

@Model
final class TaskRecord {
    var id: UUID
    var listID: UUID?
    var goalID: UUID?
    var title: String
    var status: String
    var dueDate: Date?
    var priority: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        listID: UUID? = nil,
        goalID: UUID? = nil,
        title: String,
        status: String = "open",
        dueDate: Date? = nil,
        priority: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.listID = listID
        self.goalID = goalID
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.priority = priority
        self.createdAt = createdAt
    }
}

@Model
final class ProjectRecord {
    var id: UUID
    var title: String
    var desiredOutcome: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, desiredOutcome: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.desiredOutcome = desiredOutcome
        self.createdAt = createdAt
    }
}

@Model
final class NutritionDayRecord {
    var id: UUID
    var date: Date
    var calories: Double
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var source: String

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
    var id: UUID
    var date: Date
    var wins: String
    var friction: String
    var nextFocus: String

    init(id: UUID = UUID(), date: Date, wins: String, friction: String, nextFocus: String) {
        self.id = id
        self.date = date
        self.wins = wins
        self.friction = friction
        self.nextFocus = nextFocus
    }
}

@Model
final class AppPreferenceRecord {
    var id: UUID
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

