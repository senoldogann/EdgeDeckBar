import XCTest
@testable import EdgeDeck

final class WeatherTests: XCTestCase {
    func testDefaultSampleCreation() {
        let state = WeatherState.defaultSample()
        XCTAssertEqual(state.cityName, "Istanbul")
        XCTAssertEqual(state.temperatureCelsius, 21.0)
        XCTAssertEqual(state.conditionText, "Mostly Sunny")
        XCTAssertEqual(state.hourly.count, 6)
    }

    func testWMOWeatherCodeMapping() {
        let clear = WeatherService.mapWeatherCode(code: 0)
        XCTAssertEqual(clear.text, "Clear sky")
        XCTAssertEqual(clear.symbol, "sun.max.fill")

        let rain = WeatherService.mapWeatherCode(code: 61)
        XCTAssertEqual(rain.text, "Rain")
        XCTAssertEqual(rain.symbol, "cloud.rain.fill")

        let snow = WeatherService.mapWeatherCode(code: 71)
        XCTAssertEqual(snow.text, "Snow")
        XCTAssertEqual(snow.symbol, "cloud.snow.fill")

        let storm = WeatherService.mapWeatherCode(code: 95)
        XCTAssertEqual(storm.text, "Thunderstorm")
        XCTAssertEqual(storm.symbol, "cloud.bolt.rain.fill")
    }
}
