--[[
Spellweaver in town list:
Professor Hundredeyes
Professor Ifnai
Professor Paradise
Professor Arbus

Faller
Dymion
Grath
Iron
--]]


defineTile("m", "GOLDEN_MOUNTAIN")
defineTile(';', "FLOWER")
defineTile("*", "FLOOR")
defineTile(".", "GRASS")
defineTile("t", "TREE")
defineTile("B", "KAM_WOVENHOME_BIG_TREE")
defineTile("_", "GRASS_ROAD_STONE")
defineTile("#", "HARDWALL")
defineTile("W", "KAM_WINDOW")
defineTile("=", "DOOR_OPEN")
defineTile("C", "APPROXIMATE_CAULDRON")
defineTile(">", "KAM_WOVENHOME_PATH_TO_WILDERNESS")

defineTile("1", "FLOOR", nil, "KAM_WOVENHOME_PROF_HUNDREDEYES") 
defineTile("2", "FLOOR", nil, "KAM_WOVENHOME_PROF_IFNAI")
defineTile("3", "GRASS", nil, "KAM_WOVENHOME_PROF_PARADISE")
defineTile("4", "FLOWER", nil, "KAM_WOVENHOME_PROF_ARBUS")

defineTile("5", "FLOOR", nil, "KAM_WOVENHOME_FALLER") 
defineTile("6", "FLOOR", nil, "KAM_WOVENHOME_DYMION")
defineTile("7", "GRASS", nil, "KAM_WOVENHOME_GRATH")
defineTile("8", "FLOOR", nil, "KAM_WOVENHOME_IRON")

startx = 17
starty = 31
endx = 17
endy = 31

addSpot({30, 9}, "pop-birth", "spellweavers")

return [[
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmm.......mmmmmmm............mmmmmmmmm
mmmmmmmmm...;.........mmm.....;.........mmmmmmm
mmmmm................;;;t.......t..;.......mmmm
mmm......##W####W##.t;;;;;................mmmmm
mmm..;...#********#.;;;4;;..##W###W##......mmmm
mmmm.....#*6******#.;;;;;;..#*******#...t..mmmm
mmm......#********#..;;;....#*1*****#......mmmm
mmm.t....#********#......t..#*****2*#.;.....mmm
mm.......##W#####=#.........#*******#......mmmm
mm..............._...t..;...#=####W##......mmmm
mm......t.......___.........._........;.....mmm
mm........;....__.__...;....._..;........t..mmm
mm..;.........__...__........_...............mm
mm.........____..B..__________...7t..........mm
mm....;...._..__...__..._...............t....mm
mm........._...__3__...._...;........;....;.mmm
mm...;....._....___....._...................mmm
mmm........_....._.;...#=#W###W###.........mmmm
mmm...###W#=#.;.._.....#*********#....;....mmmm
mmm...#*****#...._...;.#**8******#..t.......mmm
mmm...W*C5**W...._.....#*********#..........mmm
mmm...#*****#...._.....#*********#.;....;..mmmm
mmm...###W###.;.._..;..###W###W###.........mmmm
mmm.;............_...................t....mmmmm
mmm......t......._...t..........;.......mmmmmmm
mmmmm.......;...;_........t..........mmmmmmmmmm
mmmmmmmm......t.._...mmm.....mmmmmmmmmmmmmmmmmm
mmmmmmmmmmm......_..mmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmm._.mmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmm>mmmmmmmmmmmmmmmmmmmmmmmmmmmmm]]
