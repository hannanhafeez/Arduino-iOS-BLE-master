//
//  Constants.swift
//  Arduino-TVOS-BLE
//
//  Created by Dr. Atta on 18/06/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import Foundation

enum PeripheralNotificationKeys : String { // The notification name of peripheral
    case DisconnectNotif = "disconnectNotif" // Disconnect notification name
    case CharacteristicNotif = "characteristicNotif" // Characteristic discover notification name
}
