import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    final class Container: UIView {
        private let emitter = CAEmitterLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false

            emitter.emitterShape = .line
            layer.addSublayer(emitter)

            // Create colorful confetti cells
            let colors: [UIColor] = [
                .systemPink, .systemYellow, .systemBlue,
                .systemPurple, .systemOrange, .systemGreen, .systemTeal
            ]
            
            var cells: [CAEmitterCell] = []
            
            for color in colors {
                cells.append(Self.makeCell(color: color, scale: 0.7, velocity: 280))
                cells.append(Self.makeCell(color: color, scale: 0.5, velocity: 240))
            }

            emitter.emitterCells = cells
            emitter.birthRate = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.emitter.birthRate = 0
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: bounds.width, height: 2)
        }

        private static func makeCell(color: UIColor, scale: CGFloat, velocity: CGFloat) -> CAEmitterCell {
            let c = CAEmitterCell()
            c.birthRate = 4
            c.lifetime = 4.0
            c.velocity = velocity
            c.velocityRange = 100
            c.emissionLongitude = .pi
            c.emissionRange = .pi / 5
            c.spin = 4
            c.spinRange = 6
            c.scale = scale
            c.scaleRange = 0.3
            c.alphaSpeed = -0.3

            // Create a solid color image programmatically
            c.contents = Self.makeConfettiImage(color: color).cgImage
            
            return c
        }
        
        private static func makeConfettiImage(color: UIColor) -> UIImage {
            let size = CGSize(width: 10, height: 10)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                color.setFill()
                // Draw a square
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    }

    func makeUIView(context: Context) -> Container { Container() }
    func updateUIView(_ uiView: Container, context: Context) {}
}
