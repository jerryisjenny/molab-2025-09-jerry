//
//  ContentView.swift
//  Week03Assignment
//
//  Created by Jieyin Tan on 9/26/25.
//

import SwiftUI


let animInterval = 0.15
let lineWidth = 3.0
let baseRadius = 80.0
let maxLineLength = 150.0
let minLineLength = 20.0


let lineColors = [
  Color.red, Color.blue, Color.green, Color.orange,
  Color.purple, Color.pink, Color.cyan, Color.yellow,
  Color.mint, Color.indigo
]


struct LineData {
  var path: Path
  var color: Color
  var angle: Double
}

var currentAngle: Double = 0.0
var drawnLines: [LineData] = []
var center: CGPoint = .zero

struct CircularLinesAnimView: View {
  var body: some View {
    TimelineView(.animation(minimumInterval: animInterval)) { timeline in
      Canvas { context, size in
        // calculate the center
        center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // create new lines
        let newLine = createRandomLine(at: currentAngle, center: center)
        drawnLines.append(newLine)
        
        // draw all the lines
        for line in drawnLines {
          let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
          context.stroke(line.path, with: .color(line.color), style: style)
        }
        
        // update angle
        let angleIncrement = Double.random(in: 8...25)
        currentAngle += angleIncrement
        
        // reset
        if currentAngle >= 360 {
          currentAngle = 0
          drawnLines = []
        }
        
        // update animation
          _ = timeline.date
      }
    }
    .background(Color.white) //background
  }
}


func createRandomLine(at angle: Double, center: CGPoint) -> LineData {
    
  let radians = angle * Double.pi / 180.0
  //random length
  let lineLength = Double.random(in: minLineLength...maxLineLength)
  let randomColor = lineColors.randomElement()!
  
  // start point of line
  let startX = center.x + baseRadius * cos(radians)
  let startY = center.y + baseRadius * sin(radians)
  let startPoint = CGPoint(x: startX, y: startY)
  
  //end of line
  let endX = startX + lineLength * cos(radians)
  let endY = startY + lineLength * sin(radians)
  let endPoint = CGPoint(x: endX, y: endY)
  
  // create path
  var path = Path()
  path.move(to: startPoint)
  path.addLine(to: endPoint)
  
  return LineData(path: path, color: randomColor, angle: angle)
}


#Preview {
  CircularLinesAnimView()
}
