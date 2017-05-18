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
    
    @IBOutlet var serverAddressTextField: UITextField!
    @IBOutlet var sendTextField: UITextField!
    @IBOutlet var headerTextView: UITextView!
    @IBOutlet var bodyTextView: UITextView!
    @IBOutlet var connectButton: UIButton!
    var communicator:HJAsyncTcpCommunicator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        
        // get the HYAsyncTcpCommunicator from the hydra
        communicator = Hydra.default()?.worker(forName: HJAsyncTcpCommunicatorName) as? HJAsyncTcpCommunicator
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectButtonTouchUpInside(_ sender:AnyObject) {
        
        guard let communicator = communicator else { return }
        
        if connectButton.title(for: UIControlState()) == "Connect" {
            if serverAddressTextField.text!.characters.count > 0 {
                self.connectButton.isEnabled = false
                // get server address and port from input string format like "http://www.p9soft.com:80", "www.p9soft.com:80", "www.p9soft.com"
                let addressAndPort = self.addressAndPortPairFromString(serverAddressTextField.text!)
                // set key to given server address and port and in this case "dummy".
                communicator.setServerAddress(addressAndPort.address, port:UInt(addressAndPort.port), forKey:"dummy")
                // request connect and regist each handlers.
                
                communicator.connect(toServerKey: "dummy", timeout: 3.5, dogma: SimpleHttpDogma(), receiveHandler: { (flag:Bool, headerObject:Any?, bodyObject:Any?) in
                    if flag == true { // receive ok
                        self.headerTextView.text = String(headerObject as! NSString)
                        self.bodyTextView.text = String(bodyObject as! NSString)
                    } else { // receive failed
                        self.showAlert("Receive Failed", completion:nil)
                    }
                }, disconnectHandler: { (flag:Bool) in
                    if flag == true { // disconnect ok
                        self.showAlert("Disconnected", completion: { () -> Void in
                            self.connectButton.setTitle("Connect", for:UIControlState())
                        })
                    }
                }, completion: { (flag:Bool) in
                    if flag == true { // connect ok
                        self.connectButton.setTitle("Disconnect", for:UIControlState())
                        self.connectButton.isEnabled = true
                        self.showAlert("Connected", completion: { () -> Void in
                            if self.sendTextField.text!.characters.count == 0 {
                                self.sendTextField.text = "GET /index.html HTTP/1.1"
                            }
                        })
                    } else { // connect failed
                        self.connectButton.isEnabled = true
                        self.showAlert("Connect Failed", completion:nil)
                    }
                })
            }
        } else {
            // request disconnect.
            communicator.disconnect(fromServerKey: "dummy")
        }
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender:AnyObject) {
        
        guard let communicator = communicator else { return }
        
        var sendText = sendTextField.text
        if sendText?.characters.count == 0 {
            return
        }
        sendText! += "\r\n\r\n"
        // send
        communicator.write(toServerKey: "dummy", headerObject:sendText, bodyObject:nil, completion: { (flag:Bool) -> Void in
            if flag == false { // send failed
                self.showAlert("Not Connected", completion:nil)
            }
        })
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
}

