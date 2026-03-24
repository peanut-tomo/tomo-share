import Flutter
import UIKit

public final class TomoSharePlugin: NSObject, FlutterPlugin {
  private let telegramService = TomoTelegramService()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tomo_share", binaryMessenger: registrar.messenger())
    let instance = TomoSharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareTelegram":
      handleShareTelegram(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleShareTelegram(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(TomoShareError.invalidArguments.flutterError)
      return
    }

    guard let text = (arguments["text"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !text.isEmpty
    else {
      result(TomoShareError.missingText.flutterError)
      return
    }

    let imageFile = (arguments["imageFile"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard telegramService.isTelegramAvailable else {
      result(TomoShareError.telegramUnavailable.flutterError)
      return
    }

    do {
      let payload = try TomoTelegramSharePayload(
        text: text,
        imageFile: imageFile,
      )

      DispatchQueue.main.async {
        guard let controller = UIViewController.tomo_topMostController() else {
          result(TomoShareError.missingViewController.flutterError)
          return
        }

        let shareController = TomoTelegramShareViewController(
          payload: payload,
          service: self.telegramService,
        )

        if let popover = shareController.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(
            x: controller.view.bounds.midX,
            y: controller.view.bounds.midY,
            width: 1,
            height: 1
          )
          popover.permittedArrowDirections = []
        }

        controller.present(shareController, animated: true) {
          result(nil)
        }
      }
    } catch let error as TomoShareError {
      result(error.flutterError)
    } catch {
      result(TomoShareError.unexpected(error).flutterError)
    }
  }
}

private enum TomoShareError: Error {
  case invalidArguments
  case missingText
  case invalidImagePath(String)
  case invalidImageData(String)
  case telegramUnavailable
  case missingViewController
  case unexpected(Error)

  var flutterError: FlutterError {
    switch self {
    case .invalidArguments:
      return FlutterError(
        code: "invalid_args",
        message: "shareTelegram expects a map with text and imageFile",
        details: nil
      )
    case .missingText:
      return FlutterError(
        code: "invalid_args",
        message: "text must not be empty",
        details: nil
      )
    case let .invalidImagePath(path):
      return FlutterError(
        code: "invalid_image_path",
        message: "Unable to find image file at \(path)",
        details: nil
      )
    case let .invalidImageData(path):
      return FlutterError(
        code: "invalid_image_data",
        message: "Unable to load image data from \(path)",
        details: nil
      )
    case .telegramUnavailable:
      return FlutterError(
        code: "telegram_not_installed",
        message: "Telegram is not installed or unavailable",
        details: nil
      )
    case .missingViewController:
      return FlutterError(
        code: "missing_view_controller",
        message: "Unable to find a view controller for presenting the share sheet",
        details: nil
      )
    case let .unexpected(error):
      return FlutterError(
        code: "share_failed",
        message: error.localizedDescription,
        details: nil
      )
    }
  }
}

private final class TomoTelegramSharePayload: NSObject {
  let text: String
  let imageData: Data?
  let pasteboardType: String?

  init(
    text: String,
    imageFile: String?
  ) throws {
    self.text = text

    if let imageFile, !imageFile.isEmpty {
      guard FileManager.default.fileExists(atPath: imageFile) else {
        throw TomoShareError.invalidImagePath(imageFile)
      }

      let fileURL = URL(fileURLWithPath: imageFile)
      let imageData: Data
      do {
        imageData = try Data(contentsOf: fileURL)
      } catch {
        throw TomoShareError.invalidImagePath(imageFile)
      }

      guard UIImage(data: imageData) != nil else {
        throw TomoShareError.invalidImageData(imageFile)
      }

      self.imageData = imageData
      self.pasteboardType = Self.pasteboardType(
        for: fileURL.pathExtension
      )
    } else {
      self.imageData = nil
      self.pasteboardType = nil
    }

    super.init()
  }

  private static func pasteboardType(for fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "jpg", "jpeg":
      return "public.jpeg"
    case "png":
      return "public.png"
    case "gif":
      return "com.compuserve.gif"
    default:
      return "public.image"
    }
  }
}

private final class TomoTelegramService {
  private let telegramURL = URL(string: "tg://")!

  var isTelegramAvailable: Bool {
    UIApplication.shared.canOpenURL(telegramURL)
  }

  func openTelegram(
    with payload: TomoTelegramSharePayload,
    completion: @escaping (Bool) -> Void
  ) {
    if let imageData = payload.imageData,
       let pasteboardType = payload.pasteboardType {
      UIPasteboard.general.setData(
        imageData,
        forPasteboardType: pasteboardType
      )
      open(
        urlString: "tg://msg?text=\(payload.text)",
        completion: completion
      )
      return
    }

    open(
      urlString: "tg://msg?text=\(payload.text)",
      completion: completion
    )
  }

  private func open(
    urlString: String,
    completion: @escaping (Bool) -> Void
  ) {
    guard let encodedURLString = urlString.addingPercentEncoding(
      withAllowedCharacters: .urlQueryAllowed
    ),
      let url = URL(string: encodedURLString)
    else {
      completion(false)
      return
    }

    UIApplication.shared.open(
      url,
      options: [:],
      completionHandler: completion
    )
  }
}

private final class TomoTelegramActivity: UIActivity {
  static let customType = UIActivity.ActivityType("com.tomo.share.telegram")

  private let service: TomoTelegramService
  private var payload: TomoTelegramSharePayload?

  init(service: TomoTelegramService) {
    self.service = service
    super.init()
  }

  override class var activityCategory: UIActivity.Category {
    .share
  }

  override var activityType: UIActivity.ActivityType? {
    Self.customType
  }

  override var activityTitle: String? {
    "Telegram"
  }

  override var activityImage: UIImage? {
    UIImage(systemName: "paperplane.circle.fill")?
      .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
  }

  override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
    activityItems.contains { $0 is TomoTelegramSharePayload }
  }

  override func prepare(withActivityItems activityItems: [Any]) {
    payload = activityItems.first { $0 is TomoTelegramSharePayload }
      as? TomoTelegramSharePayload
  }

  override func perform() {
    guard let payload else {
      activityDidFinish(false)
      return
    }

    service.openTelegram(with: payload) { [weak self] success in
      self?.activityDidFinish(success)
    }
  }
}

private final class TomoTelegramShareViewController: UIActivityViewController {
  init(
    payload: TomoTelegramSharePayload,
    service: TomoTelegramService
  ) {
    super.init(
      activityItems: [payload],
      applicationActivities: [TomoTelegramActivity(service: service)]
    )
    excludedActivityTypes = Self.excludedActivities
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static var excludedActivities: [UIActivity.ActivityType] {
    var activityTypes: [UIActivity.ActivityType] = [
      .postToFacebook,
      .postToTwitter,
      .postToWeibo,
      .message,
      .mail,
      .print,
      .copyToPasteboard,
      .assignToContact,
      .saveToCameraRoll,
      .addToReadingList,
      .postToFlickr,
      .postToVimeo,
      .postToTencentWeibo,
      .airDrop,
      .openInIBooks,
      .markupAsPDF,
    ]

    if #available(iOS 15.4, *) {
      activityTypes.append(.sharePlay)
    }

    if #available(iOS 16.0, *) {
      activityTypes.append(.collaborationInviteWithLink)
      activityTypes.append(.collaborationCopyLink)
    }

    if #available(iOS 16.4, *) {
      activityTypes.append(.addToHomeScreen)
    }

    return activityTypes
  }
}

private extension UIViewController {
  static func tomo_topMostController() -> UIViewController? {
    guard let rootController = tomo_rootViewController() else {
      return nil
    }
    return tomo_topMostController(from: rootController)
  }

  static func tomo_topMostController(
    from controller: UIViewController
  ) -> UIViewController {
    if let navigationController = controller as? UINavigationController,
       let visibleController = navigationController.visibleViewController {
      return tomo_topMostController(from: visibleController)
    }

    if let tabBarController = controller as? UITabBarController,
       let selectedController = tabBarController.selectedViewController {
      return tomo_topMostController(from: selectedController)
    }

    if let presentedController = controller.presentedViewController {
      return tomo_topMostController(from: presentedController)
    }

    return controller
  }
}

private func tomo_rootViewController() -> UIViewController? {
  if #available(iOS 13.0, *) {
    let windowScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }

    for scene in windowScenes {
      if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
        return keyWindow.rootViewController
      }
    }
  }

  return UIApplication.shared.windows.first(where: \.isKeyWindow)?
    .rootViewController
}
