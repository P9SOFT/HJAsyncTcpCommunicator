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
    
    fileprivate var currentConnectedClientKey:String?
    
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
        
        resignAllResponders()
        
        if connectButton.title(for: .normal) == "Connect" {
            if let serverAddress = serverAddressTextField.text, serverAddress.count > 0 {
                self.connectButton.isEnabled = false
                // get server address and port from input string format like "http://www.p9soft.com:80", "www.p9soft.com:80", "www.p9soft.com"
                let addressAndPort = self.addressAndPortPairFromString(serverAddress)
                // set key to given server address and port
                let serverInfo = HJAsyncTcpServerInfo()
                serverInfo.address = addressAndPort.address
                serverInfo.port = addressAndPort.port as NSNumber
                HJAsyncTcpCommunicateManager.default().setServerInfo(serverInfo, forServerKey: connectServerKey)
                // request connect and regist each handlers.
                HJAsyncTcpCommunicateManager.default().connect(connectServerKey, timeout: 3.0, dogma: SimpleHttpClientDogma(), connect: { (flag, key, header, body) in
                    if flag == true { // connect ok
                        self.currentConnectedClientKey = key
                        self.connectButton.setTitle("Disconnect", for:.normal)
                        self.connectButton.isEnabled = true
                        self.sendTextField.text = "GET /index.html HTTP/1.1"
                    } else { // connect failed
                        self.connectButton.isEnabled = true
                        self.showAlert("Connect Failed", completion:nil)
                    }
                }, receive: { (flag, key, header, body) in
                    if flag == true { // receive ok
                        self.headerTextView.text = (header == nil) ? nil : String(header! as! NSString)
                        self.bodyTextView.text = (body == nil) ? nil : String(body! as! NSString)
                    }
                }, disconnect: { (flag, key, header, body) in
                    if flag == true { // disconnect ok
                        self.currentConnectedClientKey = nil
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
            if let clientKey = currentConnectedClientKey {
                HJAsyncTcpCommunicateManager.default().disconnectClient(forClientKey: clientKey)
            }
        }
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender: Any) {
        
        resignAllResponders()
        
        guard let clientKey = currentConnectedClientKey else {
            showAlert("Connect first", completion: nil)
            return
        }
        guard var headerObject = sendTextField.text, headerObject.count > 0 else {
            showAlert("Fill Send Text", completion:nil)
            return
        }
        headerObject += "\r\n\r\n"
        
        // send
        HJAsyncTcpCommunicateManager.default().sendHeaderObject(headerObject, bodyObject: nil, toClientKey: clientKey) { (flag, key, headerObject, bodyObject) in
            if flag == false { // send failed
                self.showAlert("Send Failed", completion:nil)
            }
        }
    }
    
    @IBAction func bindButtonTouchUpInside(_ sender: Any) {
        
        resignAllResponders()
        
        if bindButton.title(for: .normal) == "Bind" {
            guard let portText = portTextField.text, portText.count > 0, let port = Int(portText) else {
                showAlert("Fill Port Number", completion:nil)
                return
            }
            bindButton.isEnabled = false
            let serverInfo = HJAsyncTcpServerInfo()
            serverInfo.address = "localhost"
            serverInfo.port = port as NSNumber
            HJAsyncTcpCommunicateManager.default().setServerInfo(serverInfo, forServerKey: bindServerKey)
            HJAsyncTcpCommunicateManager.default().bind(bindServerKey, backlog: 4, dogma: SimpleHttpServerDogma(), bind: { (flag, key, header, body) in
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
                    HJAsyncTcpCommunicateManager.default().sendHeaderObject(nil, bodyObject: responseString, toClientKey: key, completion: { (flag, key, header, body) in
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
            HJAsyncTcpCommunicateManager.default().shutdownServer(forServerKey: bindServerKey)
        }
    }
    
    @IBAction func acceptableButtonTouchUpInside(_ sender: Any) {
        
        resignAllResponders()
        
        guard HJAsyncTcpCommunicateManager.default().isBinding(forServerKey: bindServerKey) == true else {
            return
        }
        
        let acceptable = HJAsyncTcpCommunicateManager.default().isAcceptable(forServerKey: bindServerKey)
        HJAsyncTcpCommunicateManager.default().setServerAcceptable(!acceptable, forServerKey: bindServerKey)
        acceptableButton.setTitle(((HJAsyncTcpCommunicateManager.default().isAcceptable(forServerKey: bindServerKey)) == true ? "Acceptable" : "Unacceptable"), for: .normal)
    }
    
    @IBAction func closeAllButtonTouchUpInside(_ sender: Any) {
        
        resignAllResponders()
        
        HJAsyncTcpCommunicateManager.default().disconnectAllClients(atServerKey: bindServerKey)
    }
    
    @IBAction func broadcastButtonTouchUpInside(_ sender: Any) {
        
        resignAllResponders()
        
        guard let bodyText = broadcastTextField.text, bodyText.count > 0 else {
            showAlert("Fill Broadcast Text", completion:nil)
            return
        }
        
        let bodyString = "<html><head><title>SimpleHttpServer</title></head><body>\(bodyText)</body></html>"
        let statusString = "HTTP/1.1 200 OK"
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        let headerString = "Date: \(dateFormater.string(from: Date()))\r\nServer: SimpleHttpServer\r\nContent-Type: text/html\r\nContent-Length: \(bodyString.lengthOfBytes(using: .utf8))"
        let responseString = "\(statusString)\r\n\(headerString)\r\n\r\n\(bodyString)"
        
        // broadcast
        HJAsyncTcpCommunicateManager.default().broadcastHeaderObject(nil, bodyObject: responseString, toServerKey: bindServerKey)
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
        
        let alert = UIAlertController(title:"Alert", message:message, preferredStyle:UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertAction.Style.default, handler:nil))
        self.present(alert, animated:true, completion:completion)
    }
    
    @objc func tcpCommunicateManagerHandler(notification:Notification) {
        
        guard let userInfo = notification.userInfo,
              let serverKey = userInfo[HJAsyncTcpCommunicateManagerParameterKeyServerKey] as? String,
              let event = userInfo[HJAsyncTcpCommunicateManagerParameterKeyEvent] as? Int else {
            return
        }
        let clientKey = userInfo[HJAsyncTcpCommunicateManagerParameterKeyClientKey] as? String ?? "--"
        
        if let event = HJAsyncTcpCommunicateManagerEvent(rawValue: event) {
            switch event {
            case .connected:
                print("- server \(serverKey) : client \(clientKey) connected.")
            case .disconnected:
                print("- server \(serverKey) : client \(clientKey) disconnected.")
            case .sent:
                print("- server \(serverKey) : client \(clientKey) sent.")
            case .received:
                print("- server \(serverKey) : client \(clientKey) received.")
            case .binded:
                print("- server \(serverKey) binded.")
            case .accepted:
                print("- server \(serverKey) : client \(clientKey) accepted.")
            case .shutdowned:
                print("- server \(serverKey) shutown")
            default:
                break
            }
        }
    }
}

