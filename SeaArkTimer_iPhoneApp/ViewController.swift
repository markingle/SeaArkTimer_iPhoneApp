import UIKit

import CoreBluetooth


// MARK: - Core Bluetooth service IDs
let Livewell_Timer_Service_CBUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")


// MARK: - Core Bluetooth characteristic IDs
let Livewell_OnOff_Switch_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a6")
let Livewell_OFFTIME_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f6-ea07361b26b7")
let Livewell_ONTIME_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f7-ea07361b26c8")
let Livewell_TIMER_Characteristic_CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f8-ea07361b26d9")


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - Core Bluetooth class member variables
    
    // Create instance variables of the
    // CBCentralManager and CBPeripheral so they
    // persist for the duration of the app's life
    var centralManager: CBCentralManager?
    var SeaArkLivewellTimer: CBPeripheral?
    
    @IBOutlet weak var connectionActivityStatus: UIActivityIndicatorView!
    
    @IBOutlet weak var powerSwitch: UISwitch!

    @IBOutlet weak var timerValueLabel: UILabel!
    @IBOutlet weak var bluetoothOffLabel: UILabel!
  
    @IBOutlet weak var onTimerSettingLabel: UILabel!
    @IBOutlet weak var offTimeSettingSlider: UISlider!
    
    @IBOutlet weak var offTimerSettingLabel: UILabel!
    @IBOutlet weak var onTimeSettingSlider: UISlider!
    
    
    // Characteristics
    private var powerState: CBCharacteristic?
    private var onTimeSetting: CBCharacteristic?
    private var offTimeSetting: CBCharacteristic?
    private var currentTime: CBCharacteristic?
    
    // MARK: - UI outlets / member variables
    
    override func viewDidLoad() {
        super.viewDidLoad()
        offTimeSettingSlider.isEnabled = false
        onTimeSettingSlider.isEnabled = false
        powerSwitch.isOn = false
        powerSwitch.isEnabled = false
        connectionActivityStatus.backgroundColor = UIColor.black
        connectionActivityStatus.startAnimating()
        // Do any additional setup after loading the view.
        
        bluetoothOffLabel.alpha = 0.0
        onTimerSettingLabel.text = String(Int(onTimeSettingSlider.value))
        offTimerSettingLabel.text = String(Int(offTimeSettingSlider.value))

        // Create a concurrent background queue for the central
        let centralQueue: DispatchQueue = DispatchQueue(label: "com.iosbrain.centralQueueName", attributes: .concurrent)
        
        // Create a central to scan for, connect to,
        // manage, and collect data from peripherals
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            bluetoothOffLabel.alpha = 1.0
        case .resetting:
            print("Bluetooth status is RESETTING")
            bluetoothOffLabel.alpha = 1.0
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            bluetoothOffLabel.alpha = 1.0
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            bluetoothOffLabel.alpha = 1.0
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            DispatchQueue.main.async { () -> Void in
                self.bluetoothOffLabel.alpha = 0.0
                self.connectionActivityStatus.backgroundColor = UIColor.black
                self.connectionActivityStatus.startAnimating()
                
            }
            // STEP 3.2: scan for peripherals that we're interested in
            centralManager?.scanForPeripherals(withServices: [Livewell_Timer_Service_CBUUID])
            print("Central Manager Looking!!")
        default: break
        } // END switch
    }
    
    // STEP 4.1: discover what peripheral devices OF INTEREST
    // are available for this app to connect to
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Peripheral Found ",peripheral.name!)
        decodePeripheralState(peripheralState: peripheral.state)
        // STEP 4.2: MUST store a reference to the peripheral in
        // class instance variable
        SeaArkLivewellTimer = peripheral
        // STEP 4.3: since ViewController
        // adopts the CBPeripheralDelegate protocol,
        // the SeaArkLivewellTimer must set its
        // delegate property to ViewController
        // (self)
        SeaArkLivewellTimer?.delegate = self
        
        // STEP 5: stop scanning to preserve battery life;
        // re-scan if disconnected
        centralManager?.stopScan()
        print("Stopped Scanning")
        
        // STEP 6: connect to the discovered peripheral of interest
        centralManager?.connect(SeaArkLivewellTimer!)
        
    } // END func centralManager(... didDiscover peripheral
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        DispatchQueue.main.async { () -> Void in
            
            self.connectionActivityStatus.backgroundColor = UIColor.green
            self.connectionActivityStatus.stopAnimating()
            self.offTimeSettingSlider.isEnabled = true
            self.onTimeSettingSlider.isEnabled = true
            self.powerSwitch.isOn = false
            self.powerSwitch.isEnabled = true
        }
        
        // STEP 8: look for services of interest on peripheral
        print("Did Connect....Looking for Timer")
        SeaArkLivewellTimer?.discoverServices([Livewell_Timer_Service_CBUUID])

    } // END func centralManager(... didConnect peripheral
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    for service in peripheral.services! {
        
        if service.uuid == Livewell_Timer_Service_CBUUID {
            
            print("Service: \(service)")
            
            // STEP 9: look for characteristics of interest
            // within services of interest
            peripheral.discoverCharacteristics(nil, for: service)
            
        }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        offTimeSettingSlider.isEnabled = false
        onTimeSettingSlider.isEnabled = false
        powerSwitch.isOn = false
        powerSwitch.isEnabled = false
        connectionActivityStatus.backgroundColor = UIColor.black
        connectionActivityStatus.startAnimating()
        centralManager?.scanForPeripherals(withServices: [Livewell_Timer_Service_CBUUID])
        print("Central Manager Looking!!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            
            print("Characteristic: \(characteristic)")
            
            if characteristic.uuid == Livewell_OnOff_Switch_Characteristic_CBUUID{
                print("Power State")
                powerState = characteristic
            }
            if characteristic.uuid == Livewell_OFFTIME_Characteristic_CBUUID{
                print("OFFTIME Found")
                offTimeSetting = characteristic
                
            }
            if characteristic.uuid == Livewell_ONTIME_Characteristic_CBUUID{
                print("ONTIME Found")
                onTimeSetting = characteristic
                
            }
            if characteristic.uuid == Livewell_TIMER_Characteristic_CBUUID{
                print("TIMER Found")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    } // END func peripheral(... didDiscoverCharacteristicsFor service
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == Livewell_TIMER_Characteristic_CBUUID {
            
            // STEP 14: we generally have to decode BLE
            // data into human readable format
            let count_n_seconds = [UInt8](characteristic.value!)
            
            print("Timer count", count_n_seconds[0])

            DispatchQueue.main.async { () -> Void in
                self.timerValueLabel.text = String(count_n_seconds[0])
            }
        } // END if characteristic.uuid ==...
        
    } // END func peripheral(... didUpdateValueFor characteristic
    
    func readTimer(using sensorLocationCharacteristic: CBCharacteristic) -> Int {
        
        let timeValue = sensorLocationCharacteristic.value!
        // convert to an array of unsigned 8-bit integers
        let data = [UInt8](timeValue)
        return Int(data[1])
        
    } // END func readSensorLocation
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        
        switch peripheralState {
            case .disconnected:
                print("Peripheral state: disconnected")
            case .connected:
                print("Peripheral state: connected")
            case .connecting:
                print("Peripheral state: connecting")
            case .disconnecting:
                print("Peripheral state: disconnecting")
        default: break
        }
        
    } // END func decodePeripheralState(peripheralState
    func writeonStateValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.writeWithoutResponse) && SeaArkLivewellTimer != nil {
            SeaArkLivewellTimer?.writeValue(value, for: characteristic, type:.withoutResponse)
        }
    }
    
    @IBAction func powerSwitchChanged(_ sender: Any) {
            print("Power State Changed")
            if powerSwitch.isOn{
                let SwitchState = "1"
                let data = Data(SwitchState.utf8)
                print("data = ", data)
                writeonStateValueToChar(withCharacteristic: powerState!, withValue: data)
            } else {
                let SwitchState = "0"
                let data = Data(SwitchState.utf8)
                print("data = ", data)
                writeonStateValueToChar(withCharacteristic: powerState!, withValue: data)
        }
        }

    @IBAction func onTimeSettingChanged(_ sender: Any) {
        print("ON Time Setting State Changed")
        let onTimerValue = String(Int(onTimeSettingSlider.value))
        self.onTimerSettingLabel.text = String(Int(onTimeSettingSlider.value))
        let data = Data(onTimerValue.utf8)
        print("on Time Setting",data)
        writeonStateValueToChar(withCharacteristic: onTimeSetting!, withValue: data)
    }
    
    @IBAction func offTimeSettingChanged(_ sender: Any) {
        print("OFF Time Setting State Changed")
        let offTimerValue = String(Int(offTimeSettingSlider.value))
        self.offTimerSettingLabel.text = String(Int(offTimeSettingSlider.value))
        let data = Data(offTimerValue.utf8)
        print("off Time Setting",data)
        writeonStateValueToChar(withCharacteristic: offTimeSetting!, withValue: data)
    }
}
