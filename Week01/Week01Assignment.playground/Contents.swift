import Foundation

// Variables for firework elements
let spark = "✦"
let star = "✨"
let dot = "·"
let boom = "💥"
let trail = "|"
let space = " "

//draw spaces
func spaces(count: Int) -> String {
    var result = ""
    if count > 0 {
        for _ in 1...count {
            result = result + space
        }
    }
    return result
}

//draw launching rocket
func launchRocket() {
    for height in 1...5 {
        print(spaces(count: 10) + "^")
        print(spaces(count: 10) + trail)
    }
    print(spaces(count: 10) + boom)
}

//draw a small firework
func smallFirework() {
    print(spaces(count: 10) + "✨")
    print(spaces(count: 9) + "✦ ✦")
    print(spaces(count: 8) + "· · ·")
}

//draw a big exploding firework
func bigFirework() {
    // Explosion
    print(spaces(count: 14) + spark)
    print(spaces(count: 12) + "✦   ✦")
    print(spaces(count: 10) + "·  " + boom + "  ·")
    print(spaces(count: 12) + "✦   ✦")
    print(spaces(count: 14) + spark)
}

//draw sparkles falling
func fallingSparkles() {
    print(spaces(count: 8) + "✨" + spaces(count: 8) + "✨")
    print(spaces(count: 10) + "·" + spaces(count: 6) + "·")
    print(spaces(count: 12) + "·" + spaces(count: 3) + "·")
}

//draw a celebration scene
func celebration() {
    for _ in 1...3 {
        print(spaces(count: 5) + "🎆" + spaces(count: 5) + "🎇" + spaces(count: 5) + "🎆")
    }
}

//draw ground with people watching
func drawGround() {
//    print("")
    print("_____________________________")
    print(" 🧍 🧍‍♀️ 🧍‍♂️ 🧍 🧍‍♀️ 🧍‍♂️ 🧍 🧍‍♀️")
    
}


// Scene 1: Launch
print("Scene 1: Launch")
launchRocket()
print("")

// Scene 2: Small fireworks
print("Scene 2: Small Burst")
smallFirework()
print("")

// Scene 3: Big explosion
print("Scene 3: Big Explosion")
bigFirework()
print("")

// Scene 4: Falling sparkles
print("Scene 4: Sparkles")
fallingSparkles()
print("")

// Scene 5: Grand finale
print("Scene 5: Grand Finale!")
celebration()

//the ground
drawGround()


