//
//  ViewController.swift
//  Arduino-IOS-BLE
//
//  Created by Dr. Atta on 20/04/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import UIKit
import Bluejay


class ViewController: UIViewController {
	
	var devices: [ScanDiscovery] = []
    var selectedSensor: PeripheralIdentifier?

	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.appDidResume),
			name: Notification.Name.UIApplicationDidBecomeActive,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.appDidBackground),
			name: Notification.Name.UIApplicationDidEnterBackground,
            object: nil
        )

        bluejay.registerDisconnectHandler(handler: self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluejay.register(connectionObserver: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bluejay.unregister(connectionObserver: self)
    }
	
	@objc func appDidResume() {
        scanDevices()
    }

    @objc func appDidBackground() {
        bluejay.stopScanning()
    }
	
	private func scanDevices() {
        if !bluejay.isScanning && !bluejay.isConnecting && !bluejay.isConnected {
            let genericAccessService = ServiceIdentifier(uuid: "1800") // 180D	//16274BFE-C539-416C-9646-CA3F991DADD6
			//"37fc19ab-98ca-4543-a68b-d183da78acdc"
			let genericAttributeService = ServiceIdentifier(uuid: "1801")
			
			
            bluejay.scan(
				
                allowDuplicates: true,
                serviceIdentifiers: [],
                discovery: { [weak self] _, discoveries -> ScanAction in
                    guard let weakSelf = self else {
                        return .stop
                    }

                    weakSelf.devices = discoveries
                    weakSelf.tableView.reloadData()

                    return .continue
                },
                expired: { [weak self] lostDiscovery, discoveries -> ScanAction in
                    guard let weakSelf = self else {
                        return .stop
                    }

                    bluejay.log("Lost discovery: \(lostDiscovery)")

                    weakSelf.devices = discoveries
                    weakSelf.tableView.reloadData()

                    return .continue
                },
                stopped: { _, error in
                    if let error = error {
                        bluejay.log("Scan stopped with error: \(error.localizedDescription)")
                    } else {
                        bluejay.log("Scan stopped without error")
                    }
                })
        }
    }


}

extension ViewController: UITableViewDelegate, UITableViewDataSource{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.devices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath)
		cell.textLabel?.text = devices[indexPath.row].peripheralIdentifier.name
		cell.detailTextLabel?.text = devices[indexPath.row].peripheralIdentifier.description
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		   let selectedSensor = devices[indexPath.row].peripheralIdentifier

		   bluejay.connect(selectedSensor, timeout: .seconds(15)) { result in
			   switch result {
			   case .success:
				   bluejay.log("Connection attempt to: \(selectedSensor.description) is successful")
			   case .failure(let error):
				   bluejay.log("Failed to connect to: \(selectedSensor.description) with error: \(error.localizedDescription)")
			   }
		   }
	   }
	
}

extension ViewController: ConnectionObserver {
    func bluetoothAvailable(_ available: Bool) {
        bluejay.log("ViewController - Bluetooth available: \(available)")

        if available {
            scanDevices()
        } else if !available {
            devices = []
            tableView.reloadData()
        }
    }

    func connected(to peripheral: PeripheralIdentifier) {
        bluejay.log("ViewController - Connected to: \(peripheral.description)")
        performSegue(withIdentifier: "toDetail", sender: self)
    }
}

extension ViewController: DisconnectHandler {
    func didDisconnect(from peripheral: PeripheralIdentifier, with error: Error?, willReconnect autoReconnect: Bool) -> AutoReconnectMode {
        
		if navigationController?.topViewController is ViewController {
            scanDevices()
        }
		

        return .noChange
    }
}
