import Foundation

@available(iOS 11.3, *)
class AccessControlFactory{
    let value: Dictionary<String, Any>
    
    init(value: Dictionary<String, Any>){
        self.value = value
    }
    
    func build() -> AccessControlParam{
        return AccessControlParam(value: value)
    }
}
