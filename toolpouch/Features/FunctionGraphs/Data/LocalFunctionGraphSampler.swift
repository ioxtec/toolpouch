import Foundation

nonisolated struct LocalFunctionGraphSampler: FunctionGraphSampling {
    private let calculator: any ScientificCalculating

    init(calculator: any ScientificCalculating) {
        self.calculator = calculator
    }

    func sample(
        expression: String,
        xRange: ClosedRange<Double>,
        angleUnit: ScientificAngleUnit,
        sampleCount: Int = 401
    ) throws -> FunctionGraph {
        guard xRange.lowerBound.isFinite,
              xRange.upperBound.isFinite,
              xRange.lowerBound < xRange.upperBound,
              (xRange.upperBound - xRange.lowerBound).isFinite else {
            throw FunctionGraphError.invalidRange
        }

        let count = max(2, min(sampleCount, 2_001))
        let step = (xRange.upperBound - xRange.lowerBound) / Double(count - 1)
        let rawValues: [(x: Double, y: Double?)] = (0..<count).map { index in
            let x = index == count - 1
                ? xRange.upperBound
                : xRange.lowerBound + Double(index) * step
            let y = try? calculator.evaluate(
                expression,
                angleUnit: angleUnit,
                variables: ["x": x]
            )
            return (x, y?.isFinite == true ? y : nil)
        }

        let finiteValues = rawValues.compactMap(\.y).sorted()
        guard !finiteValues.isEmpty else {
            throw FunctionGraphError.noDrawableValues
        }

        let yDomain = displayDomain(for: finiteValues)
        let visibleSpan = max(yDomain.upperBound - yDomain.lowerBound, 0.000_001)
        var segment = 0
        var previous: Double?
        var points: [FunctionGraphPoint] = []
        points.reserveCapacity(finiteValues.count)

        for (index, sample) in rawValues.enumerated() {
            guard let y = sample.y else {
                segment += 1
                previous = nil
                continue
            }

            if let previous,
               abs(y - previous) > visibleSpan * 4 {
                segment += 1
            }
            points.append(
                FunctionGraphPoint(
                    id: index,
                    x: sample.x,
                    y: y,
                    segment: segment
                )
            )
            previous = y
        }

        return FunctionGraph(
            expression: expression,
            angleUnit: angleUnit,
            points: points,
            xDomain: xRange,
            yDomain: yDomain
        )
    }

    private func displayDomain(for sortedValues: [Double]) -> ClosedRange<Double> {
        let lower = percentile(0.02, in: sortedValues)
        let upper = percentile(0.98, in: sortedValues)
        var span = upper - lower

        if span <= Double.ulpOfOne {
            span = max(abs(lower) * 0.2, 2)
            return (lower - span / 2)...(upper + span / 2)
        }

        let padding = span * 0.08
        return (lower - padding)...(upper + padding)
    }

    private func percentile(_ percentile: Double, in values: [Double]) -> Double {
        let position = percentile * Double(values.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        guard lowerIndex != upperIndex else { return values[lowerIndex] }
        let fraction = position - Double(lowerIndex)
        return values[lowerIndex] * (1 - fraction) + values[upperIndex] * fraction
    }
}
