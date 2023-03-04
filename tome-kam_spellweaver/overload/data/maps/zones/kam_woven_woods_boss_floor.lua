defineTile(".", "FLOOR")
defineTile("C", "CAVEWALL")
defineTile("#", "HARDWALL")

defineTile("1", "FLOOR", nil, "KAM_WOVENWOODS_CONTROLLER_CONSTRUCT")
-- defineTile("<", "UP") -- No way out. Live or die.

startx = 6
starty = 10
endx = 6
endy = 10

return [[
CCCCCCCCCCCCCC
C############C
C#..........#C
C#..........#C
C#..........#C
C#..........#C
C#..........#C
C#....1.....#C
C#..........#C
C#..........#C
C#..........#C
C#....CC....#C
C####CCCC####C
CCCCCCCCCCCCCC]]