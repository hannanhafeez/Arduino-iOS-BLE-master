//
//  ControlsTableViewController.swift
//  Arduino-TVOS-BLE
//
//  Created by Dr. Atta on 14/06/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import UIKit
import CoreBluetooth

class ControlsTableViewController: UITableViewController {

//	var device: PeripheralIdentifier?
	var dataReceived: String?
	var delegate: ViewController?
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
		   return 2
	    } else {
		   return 3
	    }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
			
			if indexPath.row == 0 {
				cell.textLabel?.text = "Device Name"
				cell.detailTextLabel?.text = self.delegate?.discoveredPeripheral?.name ?? ""
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
			cell.backgroundColor = UIColor.init(white: 1, alpha: 0.5)
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
			
			if indexPath.row == 0 {
				cell.textLabel?.text = "Disconnect"
			} else if indexPath.row == 1 {
				cell.textLabel?.text = "Turn on led"
			} else if indexPath.row == 2 {
				cell.textLabel?.text = "Turn off led"
			}
			
			return cell
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if indexPath.section == 1 {
            if indexPath.row == 0 {
				//btInstance.disconnectPeripheral()
				if let per = self.delegate?.discoveredPeripheral{
					self.delegate?.centralManager.cancelPeripheralConnection(per)
				}
            } else if indexPath.row == 1 {
				SendableAction.shared.sendON()
            } else if indexPath.row == 2 {
				SendableAction.shared.sendOFF()
            }

            tableView.deselectRow(at: indexPath, animated: true)
        }
	}
    
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			return 90
		}
		return 66
	}
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if section == 0{
			let view = UIView()
			view.backgroundColor = .clear
			return view
		}
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0{
			return 30
		}
		return 0
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


