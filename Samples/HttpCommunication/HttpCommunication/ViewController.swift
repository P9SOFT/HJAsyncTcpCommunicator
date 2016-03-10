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
        communicator = Hydra.defaultHydra().workerForName(HJAsyncTcpCommunicatorName) as? HJAsyncTcpCommunicator
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectButtonTouchUpInside(sender:AnyObject) {
        
        if connectButton.titleForState(UIControlState.Normal) == "Connect" {
            if serverAddressTextField.text!.characters.count > 0 {
                self.connectButton.enabled = false
                // get server address and port from input string format like "http://www.p9soft.com:80", "www.p9soft.com:80", "www.p9soft.com"
                let addressAndPort = self.addressAndPortPairFromString(serverAddressTextField.text!)
                // set key to given server address and port and in this case "dummy".
                communicator!.setServerAddress(addressAndPort.address, port:UInt(addressAndPort.port), forKey:"dummy")
                // request connect and regist each handlers.
                communicator!.connectToServerKey("dummy", timeout:3.5, dogma:SimpleHttpDogma(), receiveHandler: { (flag:Bool, headerObject:AnyObject!, bodyObject:AnyObject!) -> Void in
                        if flag == true { // receive ok
                            self.headerTextView.text = String(headerObject as! NSString)
                            self.bodyTextView.text = String(bodyObject as! NSString)
                        } else { // receive failed
                            self.showAlert("Receive Failed", completion:nil)
                        }
                    }, disconnectHandler: { (flag:Bool) -> Void in
                        if flag == true { // disconnect ok
                            self.showAlert("Disconnected", completion: { () -> Void in
                                self.connectButton.setTitle("Connect", forState:UIControlState.Normal)
                            })
                        }
                    }, completion: { (flag:Bool) -> Void in
                        if flag == true { // connect ok
                            self.connectButton.setTitle("Disconnect", forState:UIControlState.Normal)
                            self.connectButton.enabled = true
                            self.showAlert("Connected", completion: { () -> Void in
                                if self.sendTextField.text!.characters.count == 0 {
                                    self.sendTextField.text = "GET /index.html HTTP/1.1"
                                }
                            })
                        } else { // connect failed
                            self.connectButton.enabled = true
                            self.showAlert("Connect Failed", completion:nil)
                        }
                })
            }
        } else {
            // request disconnect.
            communicator!.disconnectFromServerKey("dummy")
        }
    }
    
    @IBAction func sendButtonTouchUpInside(sender:AnyObject) {
        
        var sendText = sendTextField.text
        if sendText?.characters.count == 0 {
            return
        }
        sendText! += "\r\n\r\n"
        // send
        communicator!.writeToServerKey("dummy", headerObject:sendText, bodyObject:nil, completion: { (flag:Bool) -> Void in
            if flag == false { // send failed
                self.showAlert("Not Connected", completion:nil)
            }
        })
    }
    
    func addressAndPortPairFromString(inputString:String) -> (address:String, port:Int) {
        
        var serverAddress = inputString
        var serverPort = 80
        var schemeAndAddressPair = serverAddress.componentsSeparatedByString("://")
        if schemeAndAddressPair.count == 2 {
            serverAddress = schemeAndAddressPair[1]
        }
        var addressAndPortPair = serverAddress.componentsSeparatedByString(":")
        if addressAndPortPair.count == 2 {
            serverAddress = addressAndPortPair[0]
            serverPort = Int(addressAndPortPair[1])!
        }
        
        return (serverAddress, serverPort)
    }
    
    func showAlert(message:String, completion:(() -> Void)?) {
        
        let alert = UIAlertController(title:"Alert", message:message, preferredStyle:UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.Default, handler:nil))
        self.presentViewController(alert, animated:true, completion:completion)
    }
}

