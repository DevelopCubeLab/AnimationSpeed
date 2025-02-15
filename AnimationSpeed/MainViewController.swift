import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let versionCode = "1.0"
    
    private var tableView = UITableView()
    
    private let tableTitleList = [NSLocalizedString("SpeedSettings", comment: ""), nil, NSLocalizedString("About", comment: "")]
    private let tableCellList = [
        ["", NSLocalizedString("Apply", comment: "")],
        [NSLocalizedString("RestoreDefault", comment: "")],
        [NSLocalizedString("Version", comment: ""), "GitHub", NSLocalizedString("Reference", comment: "")]
    ]
    
    // 标记一下每个分组的编号，防止新增一组还需要修改好几处的代码
    private let aboutAtSection = 2
    
    private var hasRootPermission = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("CFBundleDisplayName", comment: "")
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }
        
        // 检查权利
        hasRootPermission = AnimationHelper.checkInstallPermission()
        
        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册表格单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        // 将表格视图添加到主视图
        view.addSubview(tableView)

        // 设置表格视图的布局
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !AnimationHelper.checkInstallPermission() {
            showTextAlert(title: NSLocalizedString("NeedPermissionsTitle", comment: ""), message: NSLocalizedString("NeedPermissionsMessage", comment: ""))
        }
    }
    
    // MARK: - 设置总分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableTitleList.count
    }
    
    // MARK: - 设置每个分组的Cell数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableCellList[section].count
    }
    
    // MARK: - 设置每个分组的顶部标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableTitleList[section]
    }
    
    // MARK: - 构造每个Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.selectionStyle = .default
        cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
        
        if #available(iOS 13.0, *) { // 设置Label的text默认颜色
            cell.textLabel?.textColor = .label
        } else {
            cell.textLabel?.textColor = .black
        }
        
        if indexPath.section == 0 { // 设置文本框
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell")
                
                if cell == nil {
                    cell = UITableViewCell(style: .default, reuseIdentifier: "TextFieldCell")
                    cell?.selectionStyle = .none // 取消cell点击效果
                    let textField = UITextField(frame: CGRect(x: 18, y: 0, width: cell!.contentView.frame.width - 35, height: cell!.contentView.frame.height))
                    textField.placeholder = NSLocalizedString("InputAnimationSpeed", comment: "")
                    textField.borderStyle = .none  // 取消显示边框
                    textField.keyboardType = .decimalPad  // 只允许输入数字
                    textField.tag = 1 // 设置一个tag
                    textField.text = String(AnimationHelper.currentUIAnimationDragCoefficient())  // 获取设置的值或默认值
                    textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    
                    cell!.contentView.addSubview(textField)
                }
                
                return cell!
            } else if indexPath.row == 1 {
                if hasRootPermission {
                    cell.textLabel?.textColor = .systemBlue
                } else {
                    cell.textLabel?.textColor = .lightGray
                    cell.selectionStyle = .none // 取消cell点击效果
                }
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if hasRootPermission {
                    cell.textLabel?.textColor = .systemRed
                } else {
                    cell.textLabel?.textColor = .lightGray
                    cell.selectionStyle = .none // 取消cell点击效果
                }
            }
        } else if indexPath.section == aboutAtSection { // 关于
            cell.textLabel?.numberOfLines = 0 // 允许换行
            if indexPath.row == 0 {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = tableCellList[indexPath.section][indexPath.row]
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Unknown", comment: "")
                if version != versionCode { // 判断版本号是不是有人篡改
                    cell.detailTextLabel?.text = versionCode
                } else {
                    cell.detailTextLabel?.text = version
                }
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default // 启用选中效果
            }
        }
            
        return cell
    }
    
    // MARK: - Cell的点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 先隐藏键盘
        tableView.endEditing(true)
        
        if indexPath.section == 0 {
            if indexPath.row == 1 { // 应用按钮的点击事件
                if !hasRootPermission { // 无root权限不响应操作
                    return
                }
                
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)), let textField = cell.contentView.viewWithTag(1) as? UITextField {
                    NSLog("Speed -----> find cell")
//                    let inputText = textField.text ?? ""
//                    guard let newValue = Double(inputText) else {
//                        showTextAlert(title: NSLocalizedString("InvalidInput", comment: ""), message: NSLocalizedString("InputValidValue", comment: ""))
//                        return
//                    }
                    
                    let inputText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    textField.resignFirstResponder() // 关闭键盘
                    
                    let formatter = NumberFormatter()
                    formatter.locale = Locale.current
                    formatter.numberStyle = .decimal

                    guard let newValue = formatter.number(from: inputText)?.doubleValue else {
                        showTextAlert(title: NSLocalizedString("InvalidInput", comment: ""), message: NSLocalizedString("InputValidValue", comment: ""))
                        return
                    }
                    
                    let isFirstSetting = AnimationHelper.fileExists()
                    
                    // 显示确认弹窗
                    let alertController = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("ConfirmApplyMessage", comment: ""), preferredStyle: .alert)
                    // 确定按钮
                    let confirmAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .destructive) { _ in
                        if AnimationHelper.updateUIAnimationDragCoefficient(newValue: newValue) {
                            if !isFirstSetting { // 在这里判断下是否是第一次设置，首次设置注销就可以生效，第二次开始设置需要重启才能生效
                                self.showAlertWithAction(title: NSLocalizedString("Successful", comment: ""), message: String.localizedStringWithFormat(NSLocalizedString("UISpeedSetTo", comment: ""), String(newValue)), isReboot: false)
                            } else {
                                self.showAlertWithAction(title: NSLocalizedString("Successful", comment: ""), message: String.localizedStringWithFormat(NSLocalizedString("UISpeedSetTo", comment: ""), String(newValue)), isReboot: true)
                            }
                        } else {
                            self.showTextAlert(title: NSLocalizedString("Failed", comment: ""), message: NSLocalizedString("SettingFailedMessage", comment: ""))
                        }
                    }
                    // 取消按钮
                    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
                    // 添加按钮到弹窗
                    alertController.addAction(confirmAction)
                    alertController.addAction(cancelAction)
                    // 显示弹窗
                    DispatchQueue.main.async {
                        self.view.endEditing(true)
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                    
                }
            }
        } else if indexPath.section == 1 {
            if !hasRootPermission { // 无root权限不响应操作
                return
            }
            // 显示确认弹窗
            let alertController = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("ConfirmRestoreMessage", comment: ""), preferredStyle: .alert)
            // 确定按钮
            let confirmAction = UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .destructive) { _ in
                if AnimationHelper.restoreDefault() {
                    self.showAlertWithAction(title: NSLocalizedString("Successful", comment: ""), message: NSLocalizedString("RestoreDefaultSuccessfulMessage", comment: ""), isReboot: true)
                } else {
                    self.showTextAlert(title: NSLocalizedString("Failed", comment: ""), message: NSLocalizedString("SettingFailedMessage", comment: ""))
                }
            }
            // 取消按钮
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            // 添加按钮到弹窗
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            // 显示弹窗
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        } else if indexPath.section == aboutAtSection {
            if indexPath.row == 1 {
                if let url = URL(string: "https://github.com/DevelopCubeLab/AnimationSpeed") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 2 {
                if let url = URL(string: "https://www.feng.com/post/13871420") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    private func showTextAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlertWithAction(title: String, message: String, isReboot: Bool) {
        var message = message
        message.append("\n")
        
        // 确定按钮
        var confirmAction = UIAlertAction(title: NSLocalizedString("Respring", comment: ""), style: .destructive) { _ in
            let deviceController = DeviceController()
            deviceController.respring()
        }
        
        if isReboot {
            message.append(NSLocalizedString("AfterReboot", comment: ""))
            confirmAction = UIAlertAction(title: NSLocalizedString("Reboot", comment: ""), style: .destructive) { _ in
                let deviceController = DeviceController()
                deviceController.rebootDevice()
            }
        } else {
            message.append(NSLocalizedString("AfterRespring", comment: ""))
        }
        
        // 显示确认弹窗
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // 取消按钮
        let cancelAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: nil)
        // 添加按钮到弹窗
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        // 显示弹窗
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}
