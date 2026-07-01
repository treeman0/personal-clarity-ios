import Foundation

public enum GoalDirection: String, Codable, Sendable {
    case increase
    case decrease
    case maintain
}

public struct GoalSnapshot: Equatable, Sendable {
    public let title: String
    public let currentValue: Double
    public let targetValue: Double
    public let direction: GoalDirection
    public let dueDate: Date?

    public init(
        title: String,
        currentValue: Double,
        targetValue: Double,
        direction: GoalDirection,
        dueDate: Date? = nil
    ) {
        self.title = title
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.direction = direction
        self.dueDate = dueDate
    }
}

public struct HabitPlan: Equatable, Sendable {
    public let title: String
    public let weekdays: Set<Int>
    public let completions: Set<DateComponents>

    public init(title: String, weekdays: Set<Int>, completions: Set<DateComponents>) {
        self.title = title
        self.weekdays = weekdays
        self.completions = completions
    }
}

public enum TaskStatus: String, Codable, Sendable {
    case open
    case done
    case deferred
}

public struct TaskItem: Equatable, Sendable {
    public let title: String
    public let status: TaskStatus
    public let dueDate: Date?
    public let priority: Int

    public init(title: String, status: TaskStatus, dueDate: Date? = nil, priority: Int = 0) {
        self.title = title
        self.status = status
        self.dueDate = dueDate
        self.priority = priority
    }
}

public struct WeightEntry: Equatable, Sendable {
    public let date: Date
    public let pounds: Double

    public init(date: Date, pounds: Double) {
        self.date = date
        self.pounds = pounds
    }
}

public struct WeightTrend: Equatable, Sendable {
    public let latestWeight: Double?
    public let movingAverage: Double?
    public let deltaToGoal: Double?
    public let sevenDayChange: Double?
    public let weighInStreakDays: Int

    public init(
        latestWeight: Double?,
        movingAverage: Double?,
        deltaToGoal: Double?,
        sevenDayChange: Double?,
        weighInStreakDays: Int
    ) {
        self.latestWeight = latestWeight
        self.movingAverage = movingAverage
        self.deltaToGoal = deltaToGoal
        self.sevenDayChange = sevenDayChange
        self.weighInStreakDays = weighInStreakDays
    }
}

public struct NutritionDay: Equatable, Sendable {
    public let date: Date
    public let calories: Double
    public let proteinGrams: Double
    public let carbohydrateGrams: Double
    public let fatGrams: Double
    public let source: String

    public init(
        date: Date,
        calories: Double,
        proteinGrams: Double,
        carbohydrateGrams: Double,
        fatGrams: Double,
        source: String
    ) {
        self.date = date
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.source = source
    }
}

public struct DailyClaritySnapshot: Equatable, Sendable {
    public let date: Date
    public let weightTrend: WeightTrend
    public let goals: [GoalSnapshot]
    public let habitsDue: Int
    public let habitsDone: Int
    public let openTasks: [TaskItem]
    public let nutrition: NutritionDay?

    public init(
        date: Date,
        weightTrend: WeightTrend,
        goals: [GoalSnapshot],
        habitsDue: Int,
        habitsDone: Int,
        openTasks: [TaskItem],
        nutrition: NutritionDay?
    ) {
        self.date = date
        self.weightTrend = weightTrend
        self.goals = goals
        self.habitsDue = habitsDue
        self.habitsDone = habitsDone
        self.openTasks = openTasks
        self.nutrition = nutrition
    }
}

