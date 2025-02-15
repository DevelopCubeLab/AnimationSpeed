import Foundation

// Plist路径
let uIKitPlistPath = "/var/Managed Preferences/mobile/com.apple.UIKit.plist"
// 键名称
let uIAnimationKey = "UIAnimationDragCoefficient"
// 默认值
let defaultValue: Double = 1.0
/*
 查了数值对比speed：
 默认：1
 12%：0.893
 25%：0.8
 50%：0.667
 100%：0.5
 剩下的自己领悟
 */

class AnimationHelper {

    /// 检查Root权限的方法
    static func checkInstallPermission() -> Bool {
        let path = "/var/mobile/Library/Preferences"
        let writeable = access(path, W_OK) == 0
        return writeable
    }
    
    /// 检查文件是否存在
    static func fileExists() -> Bool {
        return FileManager.default.fileExists(atPath: uIKitPlistPath)
    }

    /// 如果文件不存在则创建文件并写入默认值
    static func createFileIfNeeded() -> Bool {
        guard !fileExists() else { // 文件已存在，视为成功
            return true
        }
        let defaultDict: [String: Any] = [uIAnimationKey: defaultValue]
        return (defaultDict as NSDictionary).write(toFile: uIKitPlistPath, atomically: true)
    }

    /// 更新UIAnimationDragCoefficient的值
    static func updateUIAnimationDragCoefficient(newValue: Double) -> Bool {
        // 确保文件存在
        guard createFileIfNeeded() else {
            return false
        }
        var plistDict = NSDictionary(contentsOfFile: uIKitPlistPath) as? [String: Any] ?? [:]
        plistDict[uIAnimationKey] = newValue
        
        return (plistDict as NSDictionary).write(toFile: uIKitPlistPath, atomically: true)
    }

    /// 获取当前UIAnimationDragCoefficient的值
    static func currentUIAnimationDragCoefficient() -> Double {
        guard let plistDict = NSDictionary(contentsOfFile: uIKitPlistPath) as? [String: Any],
              let value = plistDict[uIAnimationKey] as? Double else {
            return defaultValue
        }
        return value
    }

    /// 恢复默认值（删除plist文件）
    static func restoreDefault() -> Bool {
        guard fileExists() else { // 文件本来就不存在，视为成功
            return true
        }
        do {
            try FileManager.default.removeItem(atPath: uIKitPlistPath)
            return true
        } catch {
            return false
        }
    }
    
}

