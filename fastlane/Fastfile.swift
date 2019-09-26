import Foundation

class Fastfile: LaneFile {

    let project = "Lift.xcodeproj"
    let scheme = "Lift"
    let device = "iPhone Xs"

    func testLane() {
        scan(project: self.project,
             scheme: self.scheme,
             device: self.device,
             clean: true)
    }
}
