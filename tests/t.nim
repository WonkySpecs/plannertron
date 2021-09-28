import unittest
import ddnimlib / linear
import types

suite "test Facing ops":
  test "addition":
    check:
      North + East == East
      North + South == South
      North + West == West
      East + North == East
      East + West == North
      West + West == South
  
  test "subtraction":
    check:
      North - East == West
      North - West == East
      North - North == North
      East - East == North
      West - East == South

  test "identity rotation":
    let v = vec(1, 1)
    check:
      v.rotate_point(North, 3) == vec(1, 1)
      v.rotate_point(East, 3) == vec(1, 1)
      v.rotate_point(South, 3) == vec(1, 1)
      v.rotate_point(West, 3) == vec(1, 1)
  
  test "rotation":
    let v = vec(1, 0)
    check:
      v.rotate_point(North, 5) == vec(1, 0)
      v.rotate_point(East, 5) == vec(4, 1)
      v.rotate_point(South, 5) == vec(3, 4)
      v.rotate_point(West, 5) == vec(0, 3)
