/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Transfer service and characteristics UUIDs
*/

import Foundation
import CoreBluetooth

struct TransferService {
	static let serviceUUID = CBUUID(string: "37fc19ab-98ca-4543-a68b-d183da78acdc")
	static let characteristicUUID = CBUUID(string: "a40d0c2e-73ba-4d8b-8eef-9a0666992e56")
	
	static let hm10ServiceUUID = CBUUID(string: "FFE0")
	static let hm10CharacteristicUUID = CBUUID(string: "FFE1")
}
