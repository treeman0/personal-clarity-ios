import Foundation

public struct GoalProgress: Equatable, Sendable {
    public let fractionComplete: Double
    public let remaining: Double
    public let isComplete: Bool

    public init(fractionComplete: Double, remaining: Double, isComplete: Bool) {
        self.fractionComplete = fractionComplete
        self.remaining = remaining
        self.isComplete = isComplete
    }
}

public enum GoalProgressCalculator {
    public static func progress(for goal: GoalSnapshot) -> GoalProgress {
        progress(for: goal, startingValue: goal.startingValue)
    }

    public static func progress(for goal: GoalSnapshot, startingValue: Double) -> GoalProgress {
        if goal.direction == .maintain {
            let deviation = abs(goal.currentValue - goal.targetValue)
            let baseline = max(abs(startingValue - goal.targetValue), 1)
            let rawFraction = 1 - (deviation / baseline)
            let clamped = min(max(rawFraction, 0), 1)
            return GoalProgress(
                fractionComplete: clamped,
                remaining: goal.targetValue - goal.currentValue,
                isComplete: deviation <= 0.01
            )
        }

        let totalDistance = abs(goal.targetValue - startingValue)
        let remaining = goal.targetValue - goal.currentValue

        guard totalDistance > 0 else {
            return GoalProgress(fractionComplete: 1, remaining: 0, isComplete: true)
        }

        let rawFraction: Double
        switch goal.direction {
        case .increase:
            rawFraction = (goal.currentValue - startingValue) / totalDistance
        case .decrease:
            rawFraction = (startingValue - goal.currentValue) / totalDistance
        case .maintain:
            rawFraction = 1
        }

        let clamped = min(max(rawFraction, 0), 1)
        let isComplete: Bool
        switch goal.direction {
        case .increase:
            isComplete = goal.currentValue >= goal.targetValue
        case .decrease:
            isComplete = goal.currentValue <= goal.targetValue
        case .maintain:
            isComplete = true
        }

        return GoalProgress(fractionComplete: clamped, remaining: remaining, isComplete: isComplete)
    }
}
