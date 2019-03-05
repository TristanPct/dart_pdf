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

public class SwiftPrintingPlugin: NSObject, FlutterPlugin, UIPrintInteractionControllerDelegate {
    private var channel: FlutterMethodChannel?
    private var renderer: PdfPrintPageRenderer?
    private var lock: NSLock?

    init(_ channel: FlutterMethodChannel?) {
        super.init()
        self.channel = channel
        renderer = nil
        lock = NSLock()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "printing", binaryMessenger: registrar.messenger())
        let instance = SwiftPrintingPlugin(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments! as! [String: Any]
        if "printPdf" == call.method {
            printPdf(args["name"] as? String ?? "", withPrinter: args["printer"] as? String)
            result(NSNumber(value: 1))
        } else if "writePdf" == call.method {
            if let object = args["doc"] as? FlutterStandardTypedData {
                writePdf(object)
            }
            result(NSNumber(value: 1))
        } else if "sharePdf" == call.method {
            if let object = args["doc"] as? FlutterStandardTypedData {
                sharePdf(
                    object,
                    withSourceRect: CGRect(x: CGFloat((args["x"] as? NSNumber)?.floatValue ?? 0.0), y: CGFloat((args["y"] as? NSNumber)?.floatValue ?? 0.0), width: CGFloat((args["w"] as? NSNumber)?.floatValue ?? 0.0), height: CGFloat((args["h"] as? NSNumber)?.floatValue ?? 0.0)),
                    andName: args["name"] as? String
                )
            }
            result(NSNumber(value: 1))
        } else if "pickPrinter" == call.method {
            pickPrinter(result,
                        withSourceRect: CGRect(x: CGFloat((args["x"] as? NSNumber)?.floatValue ?? 0.0), y: CGFloat((args["y"] as? NSNumber)?.floatValue ?? 0.0), width: CGFloat((args["w"] as? NSNumber)?.floatValue ?? 0.0), height: CGFloat((args["h"] as? NSNumber)?.floatValue ?? 0.0)))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    func completionHandler(printController _: UIPrintInteractionController, completed: Bool, error: Error?) {
        if !completed, error != nil {
            print("Unable to print: \(error?.localizedDescription ?? "unknown error")")
        }
        renderer = nil
    }

    func printPdf(_ name: String, withPrinter printerID: String?) {
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
        
        // Direct print if printerID is non null and valid.
        if !(printerID ?? "").isEmpty {
            let printerURL = URL(string: printerID!)
            if printerURL != nil {
                let printer = UIPrinter(url: printerURL!)
//                let queue = DispatchQueue.global()
//                queue.async {
                    self.renderer?.layout()
                    controller.print(to: printer, completionHandler: self.completionHandler)
//                }
                
                return
            }
        }
        
        controller.present(animated: true, completionHandler: completionHandler)
    }

    func writePdf(_ data: FlutterStandardTypedData) {
        renderer?.setDocument(data.data)
    }

    func sharePdf(_ data: FlutterStandardTypedData, withSourceRect rect: CGRect, andName name: String?) {
        let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let uuid = CFUUIDCreate(nil)
        assert(uuid != nil)

        let uuidStr = CFUUIDCreateString(nil, uuid)
        assert(uuidStr != nil)

        var fileURL: URL
        if name == nil {
            fileURL = tmpDirURL.appendingPathComponent("document-\(uuidStr ?? "1" as CFString)").appendingPathExtension("pdf")
        } else {
            fileURL = tmpDirURL.appendingPathComponent(name!)
        }

        do {
            try data.data.write(to: fileURL, options: .atomic)
        } catch {
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
    
    func pickPrinter(_ result: @escaping FlutterResult, withSourceRect rect: CGRect) {
        let controller = UIPrinterPickerController.init(initiallySelectedPrinter: nil)
        
        let pickPrinterCompletionHandler: UIPrinterPickerController.CompletionHandler = { (printerPickerController: UIPrinterPickerController, completed: Bool, error: Error?) in
            if !completed, error != nil {
                print("Unable to pick printer: \(error?.localizedDescription ?? "unknown error")")
            }
            result(printerPickerController.selectedPrinter?.url.absoluteString)
        }
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            let viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            if viewController != nil {
                controller.present(from: rect, in: viewController!.view, animated: true, completionHandler: pickPrinterCompletionHandler)
                return
            }
        }
        
        controller.present(animated: true, completionHandler: pickPrinterCompletionHandler)
    }
}
