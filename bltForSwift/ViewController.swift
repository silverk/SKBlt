//
//  ViewController.swift
//  bltForSwift
//
//  Created by silverk on 15/6/13.
//  Copyright (c) 2015年 silverk. All rights reserved.
//

import UIKit
import CoreBluetooth


//添加代理方法
class ViewController: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate {

    //var ringing   = [0x54, 0x80,0x01, 0xa1, 0x00, 0x01, 0x00, 0x75]
    
    //设定蓝牙封装方法
    
    @IBOutlet weak var MytableView: UITableView!
    @IBAction func sendClick(sender: UIButton) {
        if(self.isConnected() == true){
            var data = NSData(bytes: [0x54, 0x80,0x01, 0xa1, 0x00, 0x01, 0x00, 0x75] as [UInt8], length: 8)
            println("data:\(data)")
            self.sendData(data)
        }
        
    }
    
    @IBOutlet weak var MyLabel: UILabel!
    var manager:CBCentralManager!
    var discaveredPeripheral:CBPeripheral!
    var writeCharacteristic : CBCharacteristic!
    var deviceList:NSMutableArray = NSMutableArray()
    var peripheralList:NSMutableArray = NSMutableArray()
    
    let serviceUUID = CBUUID(string: "FFE0")
    let ReUUID = CBUUID(string: "FFE4")  //读
    let WrUUID = CBUUID(string: "FFE1") //写
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.redColor();
        
        //初始话蓝牙设备
        self.manager=CBCentralManager(delegate: self, queue: nil)
        
        
        self.MytableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cellID")
        //self.MytableView.registerClass(UITableViewCell.self, forHeaderFooterViewReuseIdentifier: "cellID")
        //[_aboutustable registerClass:[UITableViewCell class] forCellReuseIdentifier:identify];

    }
    
    //蓝牙代理方法
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        
        if(central.state == CBCentralManagerState.PoweredOn){
            //开启扫描
            self.manager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            println("蓝牙已打开，扫描设备")
            
        }
        
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        println("发现设备:\(peripheral)")
        if(!self.deviceList.containsObject(peripheral)){
        
            self.deviceList.addObject(peripheral)
        }
        println("self.deviceList:\(self.deviceList)")
            //tableview
        self.MytableView.reloadData()
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("error:\(error) and  connect fail")
        
        
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("blt is connected")
        self.manager.stopScan()
        self.discaveredPeripheral = peripheral
        peripheral.delegate = self
        self.discaveredPeripheral.discoverServices(nil)
        
        
    }
    //判断是否连接
    func isConnected() -> Bool{
        
        return (self.discaveredPeripheral.state == CBPeripheralState.Connected)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("发现服务 :\(error)")
        
        if(error != nil){
            return
        }
        for  service in peripheral.services{
            
            println("serviceUUID:\(serviceUUID),获取到的服务号UUID:\(service.UUID)");

            if(service.UUID  == serviceUUID){
                println("serviceUUID:\(serviceUUID),获取到的服务号UUID:\(service.UUID)");

                peripheral.discoverCharacteristics(nil, forService: service as! CBService)
                break
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        
        if((error) != nil){
            return
        }
        
        //读
        for characteristic in service.characteristics{
            if(characteristic.UUID == ReUUID){
            
            peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
               println("监听到读的特征值:\(characteristic)")
                break
            }
        }
        
        for characteristic in service.characteristics{
            if(characteristic.UUID == WrUUID){
            self.writeCharacteristic = characteristic as! CBCharacteristic
                println("监听到写的特征值:\(characteristic)")

                break
            }
        
        }
        
    }
    
    //获取数据
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if((error) != nil){
            return
        }
        
        println("接收到的数据 :\(characteristic.value)")
        
        MyLabel.text = "\(characteristic.value)"
        
    }
    
    //自定义写数据方法
    func sendData(data:NSData!){

        self.discaveredPeripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: CBCharacteristicWriteType.WithResponse)
    
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("数据发送成功 OR 失败 with error :\(error)")
    }
    
    
    //定义tableview
    

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellID", forIndexPath: indexPath) as! UITableViewCell
        
        var device:CBPeripheral = self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.identifier.UUIDString
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //点击某个蓝牙
        if(self.peripheralList.containsObject(self.deviceList.objectAtIndex(indexPath.row))){
        
            self.manager.cancelPeripheralConnection(self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral)
            self.peripheralList.removeObject(self.deviceList.objectAtIndex(indexPath.row))
            self.discaveredPeripheral = nil
            println("蓝牙已断开")
            
        }else{
        
            self.discaveredPeripheral = self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral
            self.manager.connectPeripheral(self.discaveredPeripheral, options: nil)
             self.peripheralList.addObject(self.deviceList.objectAtIndex(indexPath.row))
            println("蓝牙已连接")
        }
        
        
    }
    
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

