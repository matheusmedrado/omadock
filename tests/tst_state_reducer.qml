import QtTest
import "../models/StateReducer.js" as StateReducer

TestCase {
    name: "StateReducer"

    function test_initialState() {
        var state = StateReducer.initialState()
        compare(state.name, "HIDDEN")
        compare(state.generation, 0)
    }
}
