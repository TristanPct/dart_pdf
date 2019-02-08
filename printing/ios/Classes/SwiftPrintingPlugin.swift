//  Converted to Swift 4 by Swiftify v4.2.24871 - https://objectivec2swift.com/
/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Flutter
import UIKit

class SwiftPrintingPlugin: NSObject, FlutterPlugin, UIPrintInteractionControllerDelegate {

    private var channel: FlutterMethodChannel?
    private var renderer: PdfPrintPageRenderer?

    init(_ channel: FlutterMethodChannel?) {
        super.init()
        self.channel = channel
        renderer = nil
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "printing", binaryMessenger: registrar.messenger())
    let instance = SwiftPrintingPlugin(channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }


	func handle(_ call: FlutterMethodCall, result: FlutterResult) {
		let args = call.arguments! as! Dictionary<String, Any>
		if ("printPdf" == call.method) {
			printPdf(args["name"] as? String ?? "")
            result(NSNumber(value: 1))
		} else if ("writePdf" == call.method) {
			if let object = args["doc"] as? FlutterStandardTypedData {
                writePdf(object)
            }
            result(NSNumber(value: 1))
		} else if ("sharePdf" == call.method) {
			if let object = args["doc"] as? FlutterStandardTypedData {
                sharePdf(object, withSourceRect: CGRect(x: CGFloat((args["x"] as? NSNumber)?.floatValue ?? 0.0), y: CGFloat((args["y"] as? NSNumber)?.floatValue ?? 0.0), width: CGFloat((args["w"] as? NSNumber)?.floatValue ?? 0.0), height: CGFloat((args["h"] as? NSNumber)?.floatValue ?? 0.0)))
            }
            result(NSNumber(value: 1))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    func completionHandler(printController:UIPrintInteractionController, completed:Bool, error:Error?) {
				if !completed && error != nil {
					print("Unable to print: \(error?.localizedDescription ?? "unknown error")")
				}
				self.renderer = nil
	}

    func printPdf(_ name: String) {
			let printing = UIPrintInteractionController.isPrintingAvailable
        if !printing {
            print("printing not available")
            return
        }

        let controller = UIPrintInteractionController.shared
        controller.delegate = self

        let printInfo = UIPrintInfo.printInfo()
        printInfo.jobName = name
        printInfo.outputType = .general
        controller.printInfo = printInfo
        renderer = PdfPrintPageRenderer(channel)
        controller.printPageRenderer = renderer
        controller.present(animated: true, completionHandler: completionHandler)
    }

    func writePdf(_ data: FlutterStandardTypedData) {
        renderer?.setDocument(data.data)
    }

    func sharePdf(_ data: FlutterStandardTypedData, withSourceRect rect: CGRect) {
        let tmpDirURL = URL.init(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let uuid = CFUUIDCreate(nil)
        assert(uuid != nil)

        let uuidStr = CFUUIDCreateString(nil, uuid)
        assert(uuidStr != nil)

			let fileURL = tmpDirURL.appendingPathComponent("pdf-\(uuidStr ?? "1" as CFString)").appendingPathExtension("pdf")

do {
				try data.data.write(to: fileURL, options: .atomic)
}				catch {
	print("sharePdf error: \(error.localizedDescription)")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            let controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            activityViewController.popoverPresentationController?.sourceView = controller?.view
            activityViewController.popoverPresentationController?.sourceRect = rect
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(activityViewController, animated: true)
    }
}
