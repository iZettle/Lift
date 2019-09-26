import Foundation

class Fastfile: LaneFile {

    let project = "Lift.xcodeproj"
    let scheme = "Lift"
    let device = "iPhone 8"

    func beforeAll() {
        // TODO: Add the possibility to disable this check by a parameter. Currently beforeAll can not receive parameters in fastlane swift. Maybe this will be added in the future
        // https://github.com/fastlane/fastlane/issues/15381
        xcversion(version: "10.3")
    }

    func testLane() {
        scan(project: self.project,
             scheme: self.scheme,
             device: self.device,
             clean: true)
    }
}
