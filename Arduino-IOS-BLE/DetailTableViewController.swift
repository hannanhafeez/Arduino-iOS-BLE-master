//
//  DetailTableViewController.swift
//  Arduino-IOS-BLE
//
//  Created by Dr. Atta on 23/04/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import Bluejay
import UIKit
import UserNotifications

let action1Charateristic = CharacteristicIdentifier(
    uuid: "a40d0c2e-73ba-4d8b-8eef-9a0666992e56", //83B4A431-A6F1-4540-B3EE-3C14AEF71A04
    service: ServiceIdentifier(uuid: "37fc19ab-98ca-4543-a68b-d183da78acdc")
)
let toggleActionCharacteristic = CharacteristicIdentifier(
    uuid: "a40d0c2e-73ba-4d8b-8eef-9a0666992e56", //E4D4A76C-B9F1-422F-8BBA-18508356A145
    service: ServiceIdentifier(uuid: "37fc19ab-98ca-4543-a68b-d183da78acdc")
)

let hm10ActionCharacteristic = CharacteristicIdentifier(
    uuid: "FFE1", //E4D4A76C-B9F1-422F-8BBA-18508356A145
    service: ServiceIdentifier(uuid: "FFE0")
)


class DetailTableViewController: UITableViewController {

	var device: PeripheralIdentifier?
	var dataReceived: String?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		// Uncomment the following line to preserve selection between presentations
		self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        bluejay.register(connectionObserver: self)
        bluejay.register(serviceObserver: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		bluejay.disconnect()
        bluejay.unregister(connectionObserver: self)
    }

	override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            bluejay.disconnect(immediate: true) { result in
                switch result {
                case .disconnected:
                    bluejay.log("Immediate disconnect is successful")
                case .failure(let error):
                    bluejay.log("Immediate disconnect failed with error: \(error.localizedDescription)") 
                }
            }
        }
    }

    deinit {
        bluejay.log("Deinit DetailViewController")
    }
	
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
		   return 3
	    } else {
		   return 7
	    }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)

            if indexPath.row == 0 {
                cell.textLabel?.text = "Device Name"
                cell.detailTextLabel?.text = device?.name ?? ""
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Status"
				cell.detailTextLabel?.text = bluejay.isConnected ? bluejay.isScanning ? "Disconnected" : "Connected" : "Disconnected"
			} else {
				cell.textLabel?.text = "Received"
                cell.detailTextLabel?.text = dataReceived ?? ""

                DispatchQueue.main.async {
					UIView.animate(withDuration: 0.25, animations: {
                        cell.detailTextLabel?.transform = cell.detailTextLabel!.transform.scaledBy(x: 1.5, y: 1.5)
                    }, completion: { completed in
                        if completed {
							UIView.animate(withDuration: 0.25) {
                                cell.detailTextLabel?.transform = CGAffineTransform.identity
                            }
                        }
                    })
                }
			}

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)

            if indexPath.row == 0 {
                cell.textLabel?.text = "Connect"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Disconnect"
            }
			else if indexPath.row == 2 {
                cell.textLabel?.text = "Turn on led"
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "Turn off led"
            } else if indexPath.row == 4 {
                cell.textLabel?.text = "Listen to Action 1"
            } else if indexPath.row == 5 {
                cell.textLabel?.text = "Stop listening to Action 1"
            } else if indexPath.row == 6 {
                cell.textLabel?.text = "Terminate app"
            }

            return cell
        }

    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedSensor = device else {
            bluejay.log("No sensor found")
            return
        }

        if indexPath.section == 1 {
            if indexPath.row == 0 {
                bluejay.connect(selectedSensor, timeout: .seconds(15)) { result in
                    switch result {
                    case .success:
                        bluejay.log("Connection attempt to: \(selectedSensor.description) is successful")
                    case .failure(let error):
                        bluejay.log("Failed to connect to: \(selectedSensor.description) with error: \(error.localizedDescription)")
                    }
                }
            } else if indexPath.row == 1 {
                bluejay.disconnect()
            } else if indexPath.row == 2 {
				SendableAction.shared.sendON()
            } else if indexPath.row == 3 {
				SendableAction.shared.sendOFF()
            } else if indexPath.row == 4 {
                listen(to: action1Charateristic)
            } else if indexPath.row == 5 {
                endListen(to: action1Charateristic)
            } else if indexPath.row == 6 {
                kill(getpid(), SIGKILL)
            }

            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func listen(to characteristic: CharacteristicIdentifier) {
        if characteristic == action1Charateristic {
            bluejay.listen(to: action1Charateristic, multipleListenOption: .replaceable) { (result: ReadResult<Data>) in
                switch result {
                case .success(let data):
					if let dataStr = String.init(data: data, encoding: .utf8) {
						self.dataReceived = SendableAction.shared.decryptString(string: dataStr)
						self.tableView.reloadData()
					}
                    bluejay.log("Action 1 called")
					debugPrint("Action 1 called")
                    let content = UNMutableNotificationContent()
                    content.title = "BLE Connection"
                    content.body = "Action 1 called"

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                case .failure(let error):
                    bluejay.log("Failed to listen to heart rate with error: \(error.localizedDescription)")
					
                }
            }
        }
		
		if characteristic == hm10ActionCharacteristic {
				   bluejay.listen(to: hm10ActionCharacteristic, multipleListenOption: .replaceable) { (result: ReadResult<Data>) in
					   switch result {
					   case .success(let data):
						   if let dataStr = String.init(data: data, encoding: .utf8) {
							   self.dataReceived = SendableAction.shared.decryptString(string: dataStr)
							   self.tableView.reloadData()
						   }
						   bluejay.log("Action 1 called")
						   debugPrint("Action 1 called")
						   let content = UNMutableNotificationContent()
						   content.title = "BLE Connection"
						   content.body = "Action 1 called"

						   let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
						   UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
					   case .failure(let error):
						   bluejay.log("Failed to listen to heart rate with error: \(error.localizedDescription)")
						   
					   }
				   }
			   }
		
    }
	
	private func endListen(to characteristic: CharacteristicIdentifier) {
		   bluejay.endListen(to: characteristic) { result in
			   switch result {
			   case .success:
				   bluejay.log("End listen to \(characteristic.description) is successful")
			   case .failure(let error):
				   bluejay.log("End listen to \(characteristic.description) failed with error: \(error.localizedDescription)")
			   }
		   }
	   }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DetailTableViewController: ConnectionObserver {
    func bluetoothAvailable(_ available: Bool) {
        bluejay.log("DetailViewController - Bluetooth available: \(available)")

        tableView.reloadData()
    }

    func connected(to peripheral: PeripheralIdentifier) {
        bluejay.log("DetailViewController - Connected to: \(peripheral.description)")

        device = peripheral
        listen(to: hm10ActionCharacteristic)
        listen(to: action1Charateristic)
		
        tableView.reloadData()

        let content = UNMutableNotificationContent()
        content.title = "BLE Connection"
        content.body = "Connected."

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func disconnected(from peripheral: PeripheralIdentifier) {
        bluejay.log("DetailViewController - Disconnected from: \(peripheral.description)")

        tableView.reloadData()

        let content = UNMutableNotificationContent()
        content.title = "BLE Connection"
		content.body = "\(peripheral.name) disconnected!"
		
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
		if navigationController?.topViewController is DetailTableViewController {
			DispatchQueue.main.async{
				self.navigationController?.popViewController(animated: true)
			}
        }
    }
	
	
	
}


extension DetailTableViewController: ServiceObserver {
    func didModifyServices(from peripheral: PeripheralIdentifier, invalidatedServices: [ServiceIdentifier]) {
        bluejay.log("DetailViewController - Invalidated services: \(invalidatedServices.debugDescription)")
		
        if invalidatedServices.contains(where: { invalidatedServiceIdentifier -> Bool in
            invalidatedServiceIdentifier == action1Charateristic.service
        }) {
            endListen(to: action1Charateristic)
        } else if invalidatedServices.isEmpty {
            listen(to: action1Charateristic)
        }
		
		if invalidatedServices.contains(where: { invalidatedServiceIdentifier -> Bool in
			invalidatedServiceIdentifier == hm10ActionCharacteristic.service
		}) {
			endListen(to: hm10ActionCharacteristic)
		} else if invalidatedServices.isEmpty {
			listen(to: hm10ActionCharacteristic)
		}
		
    }
}
extension DetailTableViewController: DisconnectHandler {
    func didDisconnect(from peripheral: PeripheralIdentifier, with error: Error?, willReconnect autoReconnect: Bool) -> AutoReconnectMode {
		tableView.reloadData()
		
		bluejay.disconnect()

        return .noChange
    }
	
}

