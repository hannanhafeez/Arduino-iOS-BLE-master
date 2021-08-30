//
//  Transferables.swift
//  Arduino-IOS-BLE
//
//  Created by Dr. Atta on 03/05/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import Foundation
import Bluejay

struct ToggleCommand: Sendable {

    let data: String

    init(value: String) {
        data = value
    }

    func toBluetoothData() -> Data {
        return Bluejay.combine(sendables: [data])
    }

}

