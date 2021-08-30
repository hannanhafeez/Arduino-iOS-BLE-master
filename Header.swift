//
//  Header.swift
//  Arduino-IOS-BLE
//
//  Created by Dr. Atta on 07/05/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import Foundation
#if os(iOS)
	import Bluejay
#endif

class SendableAction: NSObject {
	
	static let shared = SendableAction()
	let ENC_KEY = "d501cd4e"
	let actionsData = [
		1:"ON",			//Sends "ON" to ESP32
		2:"OFF",		//Sends "OFF" to ESP32
	]
	
	func sendON(){
		sendAction(key: 1, stringVal: actionsData[1]!)
	}
	
	func sendOFF(){
		sendAction(key: 2, stringVal: actionsData[2]!)
	}
	
	
	fileprivate func sendAction(key: Int ,stringVal: String){
		
		let stringToSend = "START-" + (key > 10 ? "0\(key)-" : "\(key)-") + "\(stringVal)-" + "\(ENC_KEY)-" + "END"
		
		let encryptedString = encryptString(string: stringToSend)
		
		#if os(iOS)
		bluejay.write(to: action1Charateristic, value: ToggleCommand(value: encryptedString)) { (result) in
			 switch result {
			   case .success:
				   debugPrint("Write to sensor location is successful.")
			   case .failure(let error):
				   debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
			}
		}
		bluejay.write(to: hm10ActionCharacteristic, value: ToggleCommand(value: encryptedString)) { (result) in
			 switch result {
			   case .success:
				   debugPrint("Write to sensor location is successful.")
			   case .failure(let error):
				   debugPrint("Failed to write sensor location with error: \(error.localizedDescription)")
			}
		}
		#endif
	}
	
	fileprivate func encryptString(string: String)->String{
		let utfData = string.data(using: .utf8)
		return utfData?.base64EncodedString() ?? "No data"
	}
	
	func decryptString(string:String) -> String {
		let data = Data.init(base64Encoded: string)
		guard data != nil else { return "" }
		let valueToUse = String.init(data: data!, encoding: .utf8)
		if let value = valueToUse{
			if value.contains(ENC_KEY){
				let dataArray = value.split(separator: "-")
				let encIndex = dataArray.firstIndex(of: Substring.init(ENC_KEY))
				guard encIndex != nil else {return ""}
				let dataIndex = encIndex!.advanced(by: -1)
				return String(dataArray[dataIndex])
			}else{
				return ""
			}
		}
		return valueToUse ?? ""
	}
	
}
