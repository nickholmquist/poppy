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

            emitter.emitterCells = [
                Self.makeCell(scale: 0.6, velocity: 260),
                Self.makeCell(scale: 0.45, velocity: 220),
                Self.makeCell(scale: 0.35, velocity: 180),
            ]

            emitter.birthRate = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.emitter.birthRate = 0
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: bounds.width, height: 2)
        }

        private static func makeCell(scale: CGFloat, velocity: CGFloat) -> CAEmitterCell {
            let c = CAEmitterCell()
            c.birthRate = 8
            c.lifetime = 3.0
            c.velocity = velocity
            c.velocityRange = 80
            c.emissionLongitude = .pi
            c.emissionRange = .pi / 6
            c.spin = 3
            c.spinRange = 4
            c.scale = scale
            c.scaleRange = 0.2
            c.alphaSpeed = -0.4

            let img = UIImage(systemName: "square.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            c.contents = img?.cgImage

            c.redRange = 1; c.greenRange = 1; c.blueRange = 1
            c.color = UIColor.systemYellow.cgColor
            return c
        }
    }

    func makeUIView(context: Context) -> Container { Container() }
    func updateUIView(_ uiView: Container, context: Context) {}
}
