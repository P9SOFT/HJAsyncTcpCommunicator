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
    
    let connectServerKey = "connectServerKey"
    let bindServerKey = "bindServerKey"
    
    @IBOutlet weak var serverAddressTextField: UITextField!
    @IBOutlet weak var sendTextField: UITextField!
    @IBOutlet weak var headerTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var bindButton: UIButton!
    @IBOutlet weak var acceptableButton: UIButton!
    @IBOutlet weak var closeAllButton: UIButton!
    @IBOutlet weak var broadcastTextField: UITextField!
    @IBOutlet weak var broadcastButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false;
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.tcpCommunicateManagerHandler(notification:)), name: NSNotification.Name(rawValue: HJAsyncTcpCommunicateManagerNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectButtonTouchUpInside(_ sender: Any) {
        
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
                HJAsyncTcpCommunicateManager.default().setServerAddress(addressAndPort.address, port: addressAndPort.port as NSNumber, parameters: nil, forKey: connectServerKey)
                // request connect and regist each handlers.
                HJAsyncTcpCommunicateManager.default().connect(toServerKey: connectServerKey, timeout: 3.0, dogma: SimpleHttpClientDogma(), connect: { (flag, key, header, body) in
                    if flag == true { // connect ok
                        self.connectButton.setTitle("Disconnect", for:.normal)
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
                }, receive: { (flag, key, header, body) in
                    if flag == true { // receive ok
                        self.headerTextView.text = (header == nil) ? nil : String(header! as! NSString)
                        self.bodyTextView.text = (body == nil) ? nil : String(body! as! NSString)
                    } else { // receive failed
                        self.showAlert("Receive Failed", completion:nil)
                    }
                }, disconnect: { (flag, key, header, body) in
                    if flag == true { // disconnect ok
                        self.showAlert("Disconnected", completion: { () -> Void in
                            self.connectButton.isEnabled = true
                            self.connectButton.setTitle("Connect", for: .normal)
                        })
                    }
                })
            } else {
                showAlert("Fill Server Address", completion: nil)
            }
        } else {
            // request disconnect.
            HJAsyncTcpCommunicateManager.default().disconnectFromServer(forKey: connectServerKey)
        }
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender: Any) {
        
        guard var headerObject = sendTextField.text, headerObject.count > 0 else {
            showAlert("Fill Send Text", completion:nil)
            return
        }
        headerObject += "\r\n\r\n"
        
        resignAllResponders()
        
        // send
        HJAsyncTcpCommunicateManager.default().sendHeaderObject(headerObject, bodyObject: nil, toServerKey: connectServerKey) { (flag, key, headerObject, bodyObject) in
            if flag == false { // send failed
                self.showAlert("Send Failed", completion:nil)
            }
        }
    }
    
    @IBAction func bindButtonTouchUpInside(_ sender: Any) {
        
        if bindButton.title(for: UIControlState()) == "Bind" {
            guard let portText = portTextField.text, portText.count > 0, let port = Int(portText) else {
                showAlert("Fill Port Number", completion:nil)
                return
            }
            bindButton.isEnabled = false
            HJAsyncTcpCommunicateManager.default().setServerAddress("localhost", port: port as NSNumber, parameters: nil, forKey: bindServerKey)
            HJAsyncTcpCommunicateManager.default().bindServerKey(bindServerKey, backlog: 4, dogma: SimpleHttpServerDogma(), bind: { (flag, key, header, body) in
                if flag == true {
                    self.bindButton.setTitle("Shutdown", for: .normal)
                } else {
                    self.showAlert("Bind failed!!", completion:nil)
                }
                self.bindButton.isEnabled = true
            }, accept: { (flag, key, header, body) in
                if flag == true, let key = key {
                    print("accept client \(key) succeed")
                }
            }, receive: { (flag, key, header, body) in
                if flag == true, let key = key, let string = body as? NSString {
                    print("client \(key) receive : \(string)")
                    let bodyString = "<html><head><title>SimpleHttpServer</title></head><body>Hello, World!</body></html>"
                    var statusString = "HTTP/1.1 400 Bad Request"
                    let range = string.range(of: "\r\n")
                    if range.location != NSNotFound {
                        let stringOnFirstline = string.substring(with: NSRange(location: 0, length: range.location))
                        let fields = stringOnFirstline.components(separatedBy: " ")
                        if fields.count > 1, fields[0] == "GET" {
                            statusString = "HTTP/1.1 200 OK"
                        }
                    }
                    let dateFormater = DateFormatter()
                    dateFormater.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
                    let headerString = "Date: \(dateFormater.string(from: Date()))\r\nServer: SimpleHttpServer\r\nContent-Type: text/html\r\nContent-Length: \(bodyString.lengthOfBytes(using: .utf8))"
                    let responseString = "\(statusString)\r\n\(headerString)\r\n\r\n\(bodyString)"
                    HJAsyncTcpCommunicateManager.default().sendHeaderObject(nil, bodyObject: responseString, toServerKey: self.bindServerKey, clientKey: key, completion: { (flag, key, header, body) in
                        if flag == true, let key = key {
                            print("response to client \(key) succeed")
                        }
                    })
                }
            }, disconnect: { (flag, key, header, body) in
                if flag == true, let key = key {
                    print("disconnect client \(key) succeed")
                }
            }, shutdown: { (flag, key, header, body) in
                if flag == true {
                    self.bindButton.setTitle("Bind", for: .normal)
                }
            })
        } else {
            HJAsyncTcpCommunicateManager.default().shutdownServer(forKey: bindServerKey)
        }
    }
    
    @IBAction func acceptableButtonTouchUpInside(_ sender: Any) {
        
        let acceptable = HJAsyncTcpCommunicateManager.default().serverAcceptable(forKey: bindServerKey)
        HJAsyncTcpCommunicateManager.default().setServerAcceptable(!acceptable, forKey: bindServerKey)
        acceptableButton.setTitle((acceptable == true ? "Acceptable" : "Unacceptable"), for: .normal)
    }
    
    @IBAction func closeAllButtonTouchUpInside(_ sender: Any) {
        
        HJAsyncTcpCommunicateManager.default().closeAllClients(atServerKey: bindServerKey)
    }
    
    @IBAction func broadcastButtonTouchUpInside(_ sender: Any) {
        
        guard var headerObject = broadcastTextField.text, headerObject.count > 0 else {
            showAlert("Fill Broadcast Text", completion:nil)
            return
        }
        headerObject += "\r\n"
        
        resignAllResponders()
        
        // broadcast
        HJAsyncTcpCommunicateManager.default().broadcastHeaderObject(nil, bodyObject: headerObject.data(using: .utf8), toServerKey: bindServerKey)
    }
    
    fileprivate func resignAllResponders() {
        
        if serverAddressTextField.isFirstResponder == true {
            serverAddressTextField.resignFirstResponder()
        }
        if sendTextField.isFirstResponder == true {
            sendTextField.resignFirstResponder()
        }
        if portTextField.isFirstResponder == true {
            portTextField.resignFirstResponder()
        }
        if broadcastTextField.isFirstResponder == true {
            broadcastTextField.resignFirstResponder()
        }
    }
    
    fileprivate func addressAndPortPairFromString(_ inputString:String) -> (address:String, port:Int) {
        
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
    
    fileprivate func showAlert(_ message:String, completion:(() -> Void)?) {
        
        let alert = UIAlertController(title:"Alert", message:message, preferredStyle:UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.default, handler:nil))
        self.present(alert, animated:true, completion:completion)
    }
    
    func tcpCommunicateManagerHandler(notification:Notification) {
        
        guard let userInfo = notification.userInfo, let key = userInfo[HJAsyncTcpCommunicateManagerParameterKeyServerKey] as? String, let event = userInfo[HJAsyncTcpCommunicateManagerParameterKeyEvent] as? Int else {
            return
        }
        
        if let event = HJAsyncTcpCommunicateManagerEvent(rawValue: event) {
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
            case .binded:
                print("- server \(key) binded.")
            case .bindFailed:
                print("- server \(key) bind failed.")
            case .accepted:
                print("- server \(key) accept client \(userInfo[HJAsyncTcpCommunicateManagerParameterKeyClientKey] ?? "")")
            case .shutdowned:
                print("- server \(key) shutown")
            default:
                break
            }
        }
    }
}

