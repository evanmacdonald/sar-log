enum FieldConditionText {
    static func readinessMessage(hasActiveTask: Bool) -> String {
        if hasActiveTask {
            "Task logging in progress."
        } else {
            "Ready for task logging."
        }
    }
}
