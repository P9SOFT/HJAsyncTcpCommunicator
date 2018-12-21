//
//  ViewController.swift
//  HttpCommunication
//
//  Created by Tae Hyun Na on 2016. 3. 7.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class ViewController: UIViewController {
    
    let serverKey = "test"
    
    @IBOutlet var serverAddressTextField: UITextField!
    @IBOutlet var sendTextField: UITextField!
    @IBOutlet var headerTextView: UITextView!
    @IBOutlet var bodyTextView: UITextView!
    @IBOutlet var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.tcpCommunicateManagerHandler(notification:)), name: NSNotification.Name(rawValue: HJAsyncTcpCommunicateManagerNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectButtonTouchUpInside(_ sender:AnyObject) {
        
        if serverAddressTextField.isFirstResponder == true {
            serverAddressTextField.resignFirstResponder()
        }
        if sendTextField.isFirstResponder == true {
            sendTextField.resignFirstResponder()
        }
        
        if connectButton.title(for: UIControlState()) == "Connect" {
            if let serverAddress = serverAddressTextField.text, serverAddress.count > 0 {
                self.connectButton.isEnabled = false
                // get server address and port from input string format like "http://www.p9soft.com:80", "www.p9soft.com:80", "www.p9soft.com"
                let addressAndPort = self.addressAndPortPairFromString(serverAddress)
                // set key to given server address and port
                HJAsyncTcpCommunicateManager.default().setServerAddress(addressAndPort.address, port: addressAndPort.port as NSNumber, parameters: nil, forKey: serverKey)
                // request connect and regist each handlers.
                HJAsyncTcpCommunicateManager.default().connect(toServerKey: serverKey, timeout: 3.0, dogma: SimpleHttpDogma(), connectHandler: { (flag, headerObject, bodyObject) in
                    if flag == true { // connect ok
                        self.connectButton.setTitle("Disconnect", for:UIControlState())
                        self.connectButton.isEnabled = true
                        self.showAlert("Connected", completion: { () -> Void in
                            if (self.sendTextField.text?.count ?? 0) == 0 {
                                self.sendTextField.text = "GET /index.html HTTP/1.1"
                            }
                        })
                    } else { // connect failed
                        self.connectButton.isEnabled = true
                        self.showAlert("Connect Failed", completion:nil)
                    }
                }, receiveHandler: { (flag, headerObject, bodyObject) in
                    if flag == true { // receive ok
                        self.headerTextView.text = String(headerObject as! NSString)
                        self.bodyTextView.text = String(bodyObject as! NSString)
                    } else { // receive failed
                        self.showAlert("Receive Failed", completion:nil)
                    }
                }, disconnect: { (flag, headerObject, bodyObject) in
                    if flag == true { // disconnect ok
                        self.showAlert("Disconnected", completion: { () -> Void in
                            self.connectButton.isEnabled = true
                            self.connectButton.setTitle("Connect", for:UIControlState())
                        })
                    }
                })
            } else {
                showAlert("Fill Server Address", completion: nil)
            }
        } else {
            // request disconnect.
            HJAsyncTcpCommunicateManager.default().disconnectFromServer(forKey: serverKey)
        }
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender:AnyObject) {
        
        guard var headerObject = sendTextField.text, headerObject.count > 0 else {
            showAlert("Fill Send Text", completion:nil)
            return
        }
        headerObject += "\r\n\r\n"
        
        if serverAddressTextField.isFirstResponder == true {
            serverAddressTextField.resignFirstResponder()
        }
        if sendTextField.isFirstResponder == true {
            sendTextField.resignFirstResponder()
        }
        
        // send
        HJAsyncTcpCommunicateManager.default().sendHeaderObject(headerObject, bodyObject: nil, toServerKey: serverKey) { (flag, headerObject, bodyObject) in
            if flag == false { // send failed
                self.showAlert("Send Failed", completion:nil)
            }
        }
    }
    
    func addressAndPortPairFromString(_ inputString:String) -> (address:String, port:Int) {
        
        var serverAddress = inputString
        var serverPort = 80
        var schemeAndAddressPair = serverAddress.components(separatedBy: "://")
        if schemeAndAddressPair.count == 2 {
            serverAddress = schemeAndAddressPair[1]
        }
        var addressAndPortPair = serverAddress.components(separatedBy: ":")
        if addressAndPortPair.count == 2 {
            serverAddress = addressAndPortPair[0]
            serverPort = Int(addressAndPortPair[1])!
        }
        return (serverAddress, serverPort)
    }
    
    func showAlert(_ message:String, completion:(() -> Void)?) {
        
        let alert = UIAlertController(title:"Alert", message:message, preferredStyle:UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.default, handler:nil))
        self.present(alert, animated:true, completion:completion)
    }
    
    func tcpCommunicateManagerHandler(notification:Notification) {
        
        guard let userInfo = notification.userInfo, let key = userInfo[HJAsyncTcpCommunicateManagerParameterKeyServerKey] as? String, let event = userInfo[HJAsyncTcpCommunicateManagerParameterKeyEvent] as? Int else {
            return
        }
        
        if key == serverKey, let event = HJAsyncTcpCommunicateManagerEvent(rawValue: event) {
            switch event {
            case .connected:
                print("- server \(key) connected.")
            case .disconnected:
                print("- server \(key) disconnected.")
            case .sent:
                print("- server \(key) sent.")
            case .sendFailed:
                print("- server \(key) send failed.")
            case .received:
                print("- server \(key) received.")
            default:
                break
            }
        }
    }
}

