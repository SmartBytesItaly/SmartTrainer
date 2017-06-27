//
//  FrmTableViewController.swift
//  SmartTrainer
//
//  Created by Alberto Ciancaleoni on 15/05/17.
//  Copyright © 2017 Smart Bytes srl. All rights reserved.
//

import UIKit

let kTableName      = "table_name"
let kColumnsArray   = "columns"
let kColName        = "col_name"
let kColType        = "col_type"
let kColLabel       = "col_label"
let kColPlaceholder = "col_placeholder"

let kStringType     = "text";
let kBoolType       = "bool";
let kNumberType     = "number";
let kLinkType       = "link";
let kImageType      = "image";

let kTargetTable    = "target";
let kTargetKey      = "target_key";
let kTargetText     = "target_text";

let kMandatory      = "mandatory";
let kMaxChar        = "max_char";
let kMaxValue       = "max_value";
let kMinValue       = "min_value";
let kStepValue      = "step_value";

class FrmTableViewController: UITableViewController, UITextFieldDelegate, TableListDelegate  {

    var recordData:NSDictionary?
    var dbTableName:String?
    var tableItems:NSMutableArray?
    let values = NSMutableArray(array: [AnyObject]())
    var selectedCell:IndexPath?
    var activeTextField:UITextField?
    var imageName:String?
    var menu:UINavigationController?
    
    func setPlistFileName(plistFileName:String)
    {
        let root = NSDictionary(contentsOfFile:Bundle.main.path(forResource: plistFileName, ofType: "plist")!)
        dbTableName = root?[kTableName] as? String
        tableItems = NSMutableArray.init(array: root![kColumnsArray] as! NSArray)
        for item in tableItems! {
            let dict = item as! Dictionary<String, Any>
            switch dict[kColType] as! String {
            case kStringType:
                values.add("")
            case kBoolType:
                values.add(false)
            case kBoolType:
                values.add(false)
            case kNumberType:
                values.add(dict[kMinValue] ?? 0.0)
            case kLinkType:
                values.add(["key":0, "text":""])
            case kBoolType:
                values.add(false)
            default:
                break
            }
        }
    }
    
    func enableSaveBtn() -> Bool
    {
        var enabled = true
        var index = 0
        outerFor:for item in values {
            let cellDesc = tableItems?.object(at: index) as! Dictionary<String, Any>
            let mandatory:Bool = cellDesc[kMandatory] as! Bool
            
            switch cellDesc[kColType] as! String {
            case kStringType:
                let value:String? = item as? String
                if mandatory && value == nil {
                    enabled = false
                    break outerFor
                }
            case kNumberType:
                let value:Float = (item as AnyObject).floatValue
                let maxValue:Float = cellDesc[kMaxValue] as! Float
                let minValue:Float = cellDesc[kMinValue] as! Float
                if mandatory && !(value >= minValue && value <= maxValue) {
                    enabled = false
                    break outerFor
                }
            case kLinkType:
                var value:Dictionary? = item as? Dictionary<String, Int>
                if mandatory && value!["key"] == 0 {
                    enabled = false
                    break outerFor
                }
            default:
                break
            }
            index += 1
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = enabled;
        return enabled;
    }

    func loadFields()
    {
        self.navigationItem.title = "New"
        var index = 0
        for item in tableItems! {
            let key:String = (item as! Dictionary<String, Any>)[kColName] as! String
            values.replaceObject(at: index, with: recordData?.object(forKey: key) ?? "")
            index += 1
        }
        enableSaveBtn();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem:UIBarButtonSystemItem.save, target: self, action: #selector(FrmTableViewController.btnSave))
        self.navigationItem.rightBarButtonItem?.isEnabled = false;
        //
        let list:NSArray? = DbManager.selectKey(kGROUPS, text: cGrName, fromTable: TABLE_GROUPS, condition: nil)! as NSArray
        let dict = [AnyHashable("key") : 0, AnyHashable("text") : "<NONE>"] as [AnyHashable : Any]
        let mutable = NSMutableArray.init(array: list!)
        mutable.insert(dict, at: 0)
        let tableList:TableListViewController = TableListViewController()
        menu = UINavigationController(rootViewController: tableList)
        tableList.delegate = self
        tableList.headerTitle = "Exercise Group"
        tableList.vociTabella = mutable as! [Any]
        tableList.selectedItem = dict
        tableList.editable = true
        menu?.modalPresentationStyle = UIModalPresentationStyle.popover
        //
        if (recordData != nil) {
            loadFields()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableItems?.count) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath)

        // Configure the cell...
        let item:Dictionary<String, Any>? = tableItems?.object(at: indexPath.row) as? Dictionary<String, Any>
        let label:UILabel = cell.viewWithTag(100) as! UILabel
        let textField:UITextField = cell.viewWithTag(101) as! UITextField
        let imageView:UIImageView = cell.viewWithTag(99) as!UIImageView
        
        label.text = item?[kColLabel] as? String
        textField.delegate = self
        textField.text = (values[indexPath.row] as AnyObject).stringValue
        textField.placeholder = item?[kColPlaceholder] as? String
        let mandatory:Bool = item![kMandatory] as! Bool
        let bundlePath:String?
        if mandatory {
            bundlePath = Bundle.main.path(forResource: "onebit_44", ofType: "png")
        } else {
            bundlePath = Bundle.main.path(forResource: "onebit_46", ofType: "png")
        }
        imageView.image = UIImage(contentsOfFile: bundlePath!)
        
        return cell
    }

    func btnSave() {
        
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let cell:UITableViewCell = Utils.cellFor(insideView: textField)
        let indexPath:NSIndexPath = tableView.indexPath(for: cell)! as NSIndexPath
        let cellDesc = tableItems?.object(at: indexPath.row) as! Dictionary<String, Any>
        if cellDesc[kColType] as! String == kLinkType {
            menu?.popoverPresentationController?.sourceView = textField
            menu?.popoverPresentationController?.sourceRect = textField.bounds
            activeTextField?.resignFirstResponder()
            //
            activeTextField = textField
            let cell:UITableViewCell = Utils.cellFor(insideView: textField)
            selectedCell = tableView.indexPath(for: cell)
            //
            self.present(menu!, animated: true, completion: nil)
            return false;
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        let cell:UITableViewCell = Utils.cellFor(insideView: textField)
        selectedCell = tableView.indexPath(for: cell)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
        selectedCell = nil
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func tableList(_ tableList: TableListViewController!, selectedItem item: [AnyHashable : Any]!) {
        if item[AnyHashable("key")] as! Int == 0 {
            activeTextField?.text = nil
        } else {
            activeTextField?.text = item[AnyHashable("text")] as? String
        }
        menu?.dismiss(animated: true, completion: nil)
    }
    
    func tableList(_ tableList: TableListViewController!, didRemoveItem item: [AnyHashable : Any]!) {
        DbManager.deleteGrp(item[AnyHashable("key")] as! Int)
    }
    
    func addItem(toTableList tableList: TableListViewController!) {
        
    }
}
