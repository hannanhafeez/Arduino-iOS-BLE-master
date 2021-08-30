//
//  InterfaceController.swift
//  BLE-watch-app WatchKit Extension
//
//  Created by Dr. Atta on 01/07/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import WatchKit
import Foundation
import CoreBluetooth
import os



class InterfaceController: WKInterfaceController {

	
	fileprivate class PeripheralInfos: Equatable, Hashable {
		let peripheral: CBPeripheral
		var RSSI: Int = 0
		var advertisementData: [String: Any] = [:]
		var lastUpdatedTimeInterval: TimeInterval
		
		init(_ peripheral: CBPeripheral) {
			self.peripheral = peripheral
			self.lastUpdatedTimeInterval = Date().timeIntervalSince1970
		}
		
		static func == (lhs: PeripheralInfos, rhs: PeripheralInfos) -> Bool {
			return lhs.peripheral.isEqual(rhs.peripheral)
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(peripheral.hash)
		}
		
	}
	
	// MARK:- Outlets
	@IBOutlet weak var scannedTableView: WKInterfaceTable!
	
	// MARK:- Variables
	var centralManager: CBCentralManager!
    var transferCharacteristic: CBCharacteristic?
	var transferCharacteristics = [CBCharacteristic]()

    var data = Data()
    var discoveredPeripheral: CBPeripheral?

	
	fileprivate var nearbyPeripheralInfos: [PeripheralInfos] = []

	
	// MARK:- Lifecycle methods
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
		setTableData()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
		centralManager.stopScan()
        os_log("Scanning stopped")

        data.removeAll(keepingCapacity: false)
        super.didDeactivate()
    }

	// MARK:- Helper Methods
	private func setTableData(){
		scannedTableView.setNumberOfRows(nearbyPeripheralInfos.count, withRowType: "deviceCell")
		
		for (n, info) in nearbyPeripheralInfos.enumerated(){
			let row = scannedTableView.rowController(at: n) as! DevicesRowController
			row.myLabel.setText(info.peripheral.name)
		}
		
	}
	
	private func retrievePeripheral() {
        
		let connectedPeripherals: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID, TransferService.hm10ServiceUUID]))
        
        os_log("Found connected Peripherals with transfer service: %@", connectedPeripherals)
        
        if let connectedPeripheral = connectedPeripherals.last {
            os_log("Connecting to peripheral %@", connectedPeripheral)
			self.discoveredPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
        } else {
            // We were not connected to our counterpart, so start scanning
			centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID, TransferService.hm10ServiceUUID],
                                               options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
	
	
	private func cleanup() {
        // Don't do anything if we're not connected
        guard let discoveredPeripheral = discoveredPeripheral,
            case .connected = discoveredPeripheral.state else { return }
        
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager.cancelPeripheralConnection(discoveredPeripheral)
    }
	
	
}

extension InterfaceController: CBCentralManagerDelegate{
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            retrievePeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch central.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
	}
	
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		let peripheralInfo = PeripheralInfos(peripheral)
        if !nearbyPeripheralInfos.contains(peripheralInfo) {
			peripheralInfo.RSSI = RSSI.intValue
			peripheralInfo.advertisementData = advertisementData
			nearbyPeripheralInfos.append(peripheralInfo)
                
        } else {
            guard let index = nearbyPeripheralInfos.firstIndex(of: peripheralInfo) else {
                return
            }
            
            let originPeripheralInfo = nearbyPeripheralInfos[index]
            let nowTimeInterval = Date().timeIntervalSince1970
            
            // If the last update within one second, then ignore it
            guard nowTimeInterval - originPeripheralInfo.lastUpdatedTimeInterval >= 1.0 else {
                return
            }
            
            originPeripheralInfo.lastUpdatedTimeInterval = nowTimeInterval
            originPeripheralInfo.RSSI = RSSI.intValue
            originPeripheralInfo.advertisementData = advertisementData
        }
		self.setTableData()
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
        cleanup()
    }
    
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        
        // Stop scanning
        centralManager.stopScan()
        os_log("Scanning stopped")
       
        // set iteration info
        // connectionIterationsComplete += 1
        // writeIterationsComplete = 0
        
        // Clear the data that we may already have
        data.removeAll(keepingCapacity: false)
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
		if discoveredPeripheral != peripheral {
				   
		   // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
		   discoveredPeripheral = peripheral
		   
		   // And finally, connect to the peripheral.
		   os_log("Connected to perhiperal %@", peripheral)
	   }
        // Search only for services that match our UUID
		peripheral.discoverServices([TransferService.serviceUUID, TransferService.hm10ServiceUUID])
		//self.detailViewController.tableView.reloadData()
		//self.setDetailVisibility(true)
    }
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		transferCharacteristics.removeAll()
		//self.setDetailVisibility(false)
		discoveredPeripheral = nil
	}
}

extension InterfaceController: CBPeripheralDelegate{
	// implementations of the CBPeripheralDelegate methods

		/*
		 *  The peripheral letting us know when services have been invalidated.
		 */
		func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
			
			for service in invalidatedServices where (service.uuid == TransferService.serviceUUID || service.uuid == TransferService.hm10ServiceUUID) {
				os_log("Transfer service is invalidated - rediscover services")
				peripheral.discoverServices([TransferService.serviceUUID, TransferService.hm10ServiceUUID])
			}
		}

		/*
		 *  The Transfer Service was discovered
		 */
		func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
			if let error = error {
				os_log("Error discovering services: %s", error.localizedDescription)
				cleanup()
				return
			}
			
			// Discover the characteristic we want...
			
			// Loop through the newly filled peripheral.services array, just in case there's more than one.
			guard let peripheralServices = peripheral.services else { return }
			
			print("\n\n")
			for service in peripheralServices {
				os_log("Service: %s", service)
				peripheral.discoverCharacteristics([TransferService.characteristicUUID, TransferService.hm10CharacteristicUUID], for: service)
			}
			print("\n\n")
		}
		
		/*
		 *  The Transfer characteristic was discovered.
		 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
		 */
		func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
			// Deal with errors (if any).
			if let error = error {
				os_log("Error discovering characteristics: %s", error.localizedDescription)
				cleanup()
				return
			}
			
			// Again, we loop through the array, just in case and check if it's the right one
			guard let serviceCharacteristics = service.characteristics else { return }
			
			print("\n\n")
			for characteristic in serviceCharacteristics where (characteristic.uuid == TransferService.characteristicUUID || characteristic.uuid == TransferService.hm10CharacteristicUUID) {
				// If it is, subscribe to it
				os_log("Charateristic: %s", characteristic)

				if transferCharacteristics.contains(characteristic){continue}
				peripheral.setNotifyValue(true, for: characteristic)
			}
			print("\n\n")
			// Once this is complete, we just need to wait for the data to come in.
		}
		
		/*
		 *   This callback lets us know more data has arrived via notification on the characteristic
		 */
		func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
			// Deal with errors (if any)
			if let error = error {
				os_log("Error discovering characteristics: %s", error.localizedDescription)
				cleanup()
				return
			}
			
			guard let characteristicData = characteristic.value,
				let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
			
			os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
			
			// Have we received the end-of-message token?
	//        if stringFromData == "EOM" {
	//            // End-of-message case: show the data.
	//            // Dispatch the text view update to the main queue for updating the UI, because
	//            // we don't know which thread this method will be called back on.
	//            DispatchQueue.main.async() {
	//                self.textView.text = String(data: self.data, encoding: .utf8)
	//            }
	//
	//            // Write test data
	//            writeData()
	//        } else {
	//            // Otherwise, just append the data to what we have previously received.
	//            data.append(characteristicData)
	//        }
		}

		/*
		 *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
		 */
		func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
			// Deal with errors (if any)
			if let error = error {
				os_log("Error changing notification state: %s", error.localizedDescription)
				return
			}
			
			// Exit if it's not the transfer characteristic
			guard characteristic.uuid == TransferService.characteristicUUID ||
			characteristic.uuid == TransferService.hm10CharacteristicUUID else { return }
			
			if characteristic.isNotifying {
				// Notification has started
				os_log("Notification began on %@", characteristic)
			} else {
				// Notification has stopped, so disconnect from the peripheral
				os_log("Notification stopped on %@. Disconnecting", characteristic)
				cleanup()
			}
			
		}
		
		/*
		 *  This is called when peripheral is ready to accept more data when using write without response
		 */
		func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
			os_log("Peripheral is ready, send data")
	//        writeData()
		}
		
}
