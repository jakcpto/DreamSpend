import Foundation
@testable import DreamSpend

final class InMemoryPersistenceController: PersistenceControllerProtocol {
    var snapshot: GameSnapshot?

    func loadSnapshot() -> GameSnapshot? {
        snapshot
    }

    func saveSnapshot(_ snapshot: GameSnapshot) {
        self.snapshot = snapshot
    }
}
