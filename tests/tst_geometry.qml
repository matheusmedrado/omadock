import QtTest
import "../models/Geometry.js" as Geometry

TestCase {
    name: "Geometry"

    function test_intersection() {
        verify(Geometry.intersects({ x: 0, y: 0, width: 10, height: 10 },
                                   { x: 5, y: 5, width: 10, height: 10 }))
        verify(!Geometry.intersects({ x: 0, y: 0, width: 10, height: 10 },
                                    { x: 10, y: 0, width: 10, height: 10 }))
    }
}
