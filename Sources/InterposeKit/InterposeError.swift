import Foundation

/// An error representing failure to prepare, apply, or revert a hook.
public enum InterposeError: Error, @unchecked Sendable {
    
    /// A hook operation failed and the hook is no longer usable.
    case hookInFailedState
    
    /// No method of the given kind found for the selector on the specified class.
    ///
    /// This typically occurs when mistyping a stringified selector or attempting to hook
    /// a method that does not exist on the class.
    case methodNotFound(
        class: AnyClass,
        kind: MethodKind,
        selector: Selector
    )

    /// The method for the selector is inherited from a superclass rather than directly implemented
    /// by the specified class.
    ///
    /// Class-based interposing only supports methods directly implemented by the class itself.
    /// This restriction ensures safe reverting via `revert()`, which cannot remove dynamically
    /// added methods.
    ///
    /// To interpose this method, consider hooking the superclass that provides the implementation,
    /// or use object-based hooking on a specific instance instead.
    case methodNotDirectlyImplemented(
        class: AnyClass,
        kind: MethodKind,
        selector: Selector
    )
    
    /// No implementation found for a method of the given kind matching the selector on the class.
    ///
    /// This should not occur under normal conditions and may indicate an invalid or misconfigured
    /// runtime state.
    case implementationNotFound(
        class: AnyClass,
        kind: MethodKind,
        selector: Selector
    )
    
    /// The method implementation was changed externally after the hook was applied, and the revert
    /// operation has removed that unexpected implementation.
    ///
    /// This typically indicates that another system modified the method after interposing.
    /// In such cases, `Hook.revert()` is unsafe and should be avoided.
    case revertCorrupted(
        class: AnyClass,
        kind: MethodKind,
        selector: Selector,
        imp: IMP?
    )
    
    /// Failed to create a dynamic subclass for the given object.
    ///
    /// This can occur if the desired subclass name is already in use. While InterposeKit
    /// generates globally unique subclass names using an internal counter, a name collision may
    /// still happen if another system has registered a class with the same name earlier during
    /// the process lifetime.
    case subclassCreationFailed(
        subclassName: String,
        object: NSObject
    )
    
    /// Detected Key-Value Observing on the object while applying or reverting a hook.
    ///
    /// The KVO mechanism installs its own dynamic subclass at runtime but does not support
    /// additional method overrides. Applying or reverting hooks on an object under KVO can lead
    /// to crashes in the Objective-C runtime, so such operations are explicitly disallowed.
    ///
    /// It is safe to start observing an object *after* it has been hooked, but not the other way
    /// around. Once KVO is active, reverting an existing hook is also considered unsafe.
    case kvoDetected(object: NSObject)
    
    /// The object uses a dynamic subclass that was not installed by InterposeKit.
    ///
    /// This typically indicates interference from another runtime system, such as method
    /// swizzling libraries (like [Aspects](https://github.com/steipete/Aspects)). Similar to KVO,
    /// such subclasses bypass normal safety checks. Hooking is disallowed in this case to
    /// avoid crashes.
    ///
    /// - Note: Use `NSStringFromClass` to print class names accurately. Swift’s default
    ///   formatting may reflect the perceived, not the actual runtime class.
    case unexpectedDynamicSubclass(
        object: NSObject,
        actualClass: AnyClass
    )
    
    /// Failed to add a super trampoline for the specified class and selector.
    ///
    /// When interposing an instance method on a dynamic subclass, InterposeKit installs
    /// a *super trampoline*—a method that forwards calls to the original implementation
    /// in the superclass. This allows the hook to delegate to the original behavior when needed.
    ///
    /// This error is thrown when the trampoline cannot be added, which is very rare.
    /// Refer to the underlying error for more details.
    case failedToAddSuperTrampoline(
        class: AnyClass,
        selector: Selector,
        underlyingError: NSError
    )
    
    case unsupportedKVO(object: NSObject)
}

extension InterposeError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
        case let .methodNotFound(lhsClass, lhsKind, lhsSelector):
            switch rhs {
            case let .methodNotFound(rhsClass, rhsKind, rhsSelector):
                return lhsClass == rhsClass
                && lhsKind == rhsKind
                && lhsSelector == rhsSelector
            default:
                return false
            }
            
        case let .methodNotDirectlyImplemented(lhsClass, lhsKind, lhsSelector):
            switch rhs {
            case let .methodNotDirectlyImplemented(rhsClass, rhsKind, rhsSelector):
                return lhsClass == rhsClass
                && lhsKind == rhsKind
                && lhsSelector == rhsSelector
            default:
                return false
            }
            
        case let .implementationNotFound(lhsClass, lhsKind, lhsSelector):
            switch rhs {
            case let .implementationNotFound(rhsClass, rhsKind, rhsSelector):
                return lhsClass == rhsClass
                && lhsKind == rhsKind
                && lhsSelector == rhsSelector
            default:
                return false
            }
            
        case let .revertCorrupted(lhsClass, lhsKind, lhsSelector, lhsIMP):
            switch rhs {
            case let .revertCorrupted(rhsClass, rhsKind, rhsSelector, rhsIMP):
                return lhsClass == rhsClass
                && lhsKind == rhsKind
                && lhsSelector == rhsSelector
                && lhsIMP == rhsIMP
            default:
                return false
            }
            
        case let .subclassCreationFailed(lhsName, lhsObject):
            switch rhs {
            case let .subclassCreationFailed(rhsName, rhsObject):
                return lhsName == rhsName && lhsObject === rhsObject
            default:
                return false
            }
            
        case let .kvoDetected(lhsObject):
            switch rhs {
            case let .kvoDetected(rhsObject):
                return lhsObject === rhsObject
            default:
                return false
            }
            
        case let .unexpectedDynamicSubclass(lhsObject, lhsClass):
            switch rhs {
            case let .unexpectedDynamicSubclass(rhsObject, rhsClass):
                return lhsObject === rhsObject && lhsClass == rhsClass
            default:
                return false
            }
            
        case let .failedToAddSuperTrampoline(lhsClass, lhsSelector, lhsError):
            switch rhs {
            case let .failedToAddSuperTrampoline(rhsClass, rhsSelector, rhsError):
                return lhsClass == rhsClass
                && lhsSelector == rhsSelector
                && lhsError.domain == rhsError.domain
                && lhsError.code == rhsError.code
            default:
                return false
            }
            
        case .hookInFailedState:
            switch rhs {
            case .hookInFailedState:
                return true
            default:
                return false
            }
            
        case .unsupportedKVO:
            switch rhs {
            case .unsupportedKVO:
                return true
            default:
                return false
            }
        }
    }
}
