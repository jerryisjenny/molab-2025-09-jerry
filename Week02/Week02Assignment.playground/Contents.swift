import UIKit

let canvasSize = CGSize(width: 1024, height: 1024)
let renderer = UIGraphicsImageRenderer(size: canvasSize)

let generatedImage = renderer.image { context in
    let ctx = context.cgContext
    let bounds = renderer.format.bounds
    UIColor.white.setFill()
    context.fill(bounds)
    let num = 20
    let size1: CGFloat = 50
    let scaleX = bounds.width / 800.0
    let scaleY = bounds.height / 500.0
    
    
    for j in 0..<15 {
        let freq = Double(j) * 0.9
        let amp: CGFloat = 40 * scaleY
        let sinValue = sin(freq) * amp
        
        ctx.saveGState()
        let translateX: CGFloat = 55 * scaleX * CGFloat(j + 1)
        let translateY: CGFloat = (44 + sinValue) * scaleY
        
        var y2: CGFloat = 0
        while y2 < bounds.height {
            let angle = CGFloat(j) * 90 * .pi / 180 + y2 * 0.01
            ctx.saveGState()
            
            let drawX = translateX + (-23 * scaleX)
            let drawY = translateY + y2
            ctx.translateBy(x: drawX, y: drawY)
            ctx.rotate(by: angle)
           
            for d in 0..<10 {
                let randomScale = CGFloat.random(in: 0.1...2.0)
                
                ctx.saveGState()
                ctx.scaleBy(x: randomScale, y: randomScale)
                
                // learn from AI
                let red = CGFloat.random(in: 0...1)
                let green = CGFloat.random(in: 0...1)
                let blue = CGFloat.random(in: 0...1)
                let alpha = CGFloat.random(in: 0.4...0.9)
                ctx.setStrokeColor(red: red, green: green, blue: blue, alpha: alpha)
                
                let strokeWidth = CGFloat.random(in: 1.5...4.0)
                ctx.setLineWidth(strokeWidth)

                let rectWidth = CGFloat.random(in: 12...120) * scaleX
                let rectHeight = CGFloat.random(in: 12...120) * scaleY
                let rect = CGRect(x: -rectWidth/2, y: -rectHeight/2, width: rectWidth, height: rectHeight)
                ctx.stroke(rect)
                
                ctx.restoreGState()
            }
            
            ctx.restoreGState()
            y2 += 30 * scaleY
        }
        
        ctx.restoreGState()
    }
    
}

generatedImage

func saveGeneratedImage() {
    guard let imageData = generatedImage.pngData() else { return }
    
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let imagePath = documentsPath.appendingPathComponent("generative_pattern_1024x1024.png")
    
    do {
        try imageData.write(to: imagePath)
        print("Save: \(imagePath.path)")
        print("Terminal: cp \(imagePath.path) ~/Downloads/")
    } catch {
        print("Fail: \(error)")
    }
}

saveGeneratedImage()

