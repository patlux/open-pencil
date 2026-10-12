//! Keep the editor responsive for MCP while its window is not visible.
//!
//! `backgroundThrottling: "disabled"` only stops WebKit from suspending the page.
//! When the window is on another Space or fully covered, WebKit still drops the web
//! content to a background process assertion, and App Nap throttles the app itself.
//! On a busy Mac, MCP calls then exceed the bridge's 20 s RPC timeout.
//!
//! Hidden (Cmd-H) or minimized windows still lower the web content priority: WebKit
//! treats them as not visible regardless of these settings.

use objc2::msg_send;
use objc2::runtime::{AnyClass, AnyObject};

/// `NSActivityUserInitiatedAllowingIdleSystemSleep`
const USER_INITIATED_ALLOWING_IDLE_SLEEP: u64 = 0x00FF_FFFF & !(1 << 20);

/// Keeps WebKit from treating an occluded window (other Space, fully covered) as
/// invisible. Uses private WebKit SPI and returns `false` when it is unavailable.
///
/// # Safety
///
/// `webview` must point to a live `WKWebView`; call this on the main thread.
pub unsafe fn disable_occlusion_detection(webview: *mut AnyObject) -> bool {
    let selector = objc2::sel!(_setWindowOcclusionDetectionEnabled:);
    let supported: bool = !webview.is_null() && msg_send![webview, respondsToSelector: selector];
    if supported {
        let _: () = msg_send![webview, _setWindowOcclusionDetectionEnabled: false];
    }
    supported
}

/// Opts the process out of App Nap for its whole lifetime; idle system sleep stays
/// allowed. Returns `false` when the activity could not be started.
pub fn disable_app_nap() -> bool {
    let (Some(process_info), Some(string)) =
        (AnyClass::get(c"NSProcessInfo"), AnyClass::get(c"NSString"))
    else {
        return false;
    };
    // SAFETY: plain Foundation calls with valid receivers and a static C string.
    unsafe {
        let info: *mut AnyObject = msg_send![process_info, processInfo];
        let reason: *mut AnyObject = msg_send![
            string,
            stringWithUTF8String: c"OpenPencil MCP automation".as_ptr()
        ];
        let activity: *mut AnyObject = msg_send![
            info,
            beginActivityWithOptions: USER_INITIATED_ALLOWING_IDLE_SLEEP,
            reason: reason
        ];
        if activity.is_null() {
            return false;
        }
        // The activity ends when its token is released; keep it until the process exits.
        let _: *mut AnyObject = msg_send![activity, retain];
    }
    true
}
