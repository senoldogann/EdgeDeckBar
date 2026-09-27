import Foundation
import SwiftUI

public struct WeatherFlyoutView: View {
    public let state: WeatherState
    public let onRefresh: () -> Void

    public init(
        state: WeatherState,
        onRefresh: @escaping () -> Void
    ) {
        self.state = state
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(spacing: 16.0) {
            // Header
            HStack {
                HStack(spacing: 6.0) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11.0))
                        .foregroundColor(.accentColor)
                    Text(state.cityName)
                        .font(.system(size: 13.0, weight: .bold))
                }

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh Weather")
                        .font(.system(size: 12.0))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            // Hero Weather Card
            VStack(spacing: 6.0) {
                Image(systemName: state.symbolName)
                    .font(.system(size: 48.0))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: Color.orange.opacity(0.30), radius: 8.0, x: 0.0, y: 4.0)
                    .padding(.top, 4.0)

                Text("\(Int(round(state.temperatureCelsius)))°")
                    .font(.system(size: 46.0, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Text(state.conditionText)
                    .font(.system(size: 14.0, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 12.0) {
                    Text("H: \(Int(round(state.highCelsius)))°")
                        .font(.system(size: 12.0, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("L: \(Int(round(state.lowCelsius)))°")
                        .font(.system(size: 12.0, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.80))
                }
                .padding(.horizontal, 10.0)
                .padding(.vertical, 4.0)
                .liquidGlassPill(accentColor: nil)
            }
            .padding(.vertical, 4.0)

            // Hourly Forecast Strip
            VStack(alignment: .leading, spacing: 8.0) {
                Text("HOURLY FORECAST")
                    .font(.system(size: 10.0, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.80))
                    .padding(.horizontal, 4.0)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10.0) {
                        ForEach(state.hourly) { forecast in
                            VStack(spacing: 8.0) {
                                Text(forecast.hour)
                                    .font(.system(size: 11.0, weight: .medium))
                                    .foregroundColor(.secondary)

                                Image(systemName: forecast.symbolName)
                                    .font(.system(size: 18.0))
                                    .symbolRenderingMode(.multicolor)
                                    .frame(height: 22.0)

                                Text("\(Int(round(forecast.temperatureCelsius)))°")
                                    .font(.system(size: 12.0, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 10.0)
                            .padding(.horizontal, 10.0)
                            .liquidGlassCard(cornerRadius: 12.0, isHovered: false)
                        }
                    }
                    .padding(.horizontal, 2.0)
                }
            }

            Spacer()
        }
        .padding(16.0)
    }
}
