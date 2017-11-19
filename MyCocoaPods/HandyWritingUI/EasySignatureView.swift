//
//  EasySignatureView.swift
//  SwiftTestDemo
//
//  Created by zhengxh on 2017/11/13.
//  Copyright © 2017年 zhengxh. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore


public protocol SignatureViewProtocol {
    func getSignatureImg(image: UIImage)
    func onSignatureWriteAction()
}

let strWidth: CGFloat   = 210
let strHeight: CGFloat  = 20

//中间点
public func midpoint(p0: CGPoint, p1: CGPoint) -> CGPoint  {
    return CGPoint.init(x: ( (p0.x + p1.x) / 2.0), y: ( (p0.y + p1.y) / 2.0))
}

public class EasySignatureView: UIView {
    public var showMessage: String = ""
    public var signatureImg: UIImage?
    public var currentPointArr: NSMutableArray!
    public var hasSignatureImg: Bool = false
    public var delegate: SignatureViewProtocol?
    
    private var min: CGFloat = 0
    private var max: CGFloat = 0
    private var origRect: CGRect = CGRect.zero
    private var origionX: CGFloat = 0
    private var totoalWidth: CGFloat = 0
    private var isSure: Bool = false
    
    private var path: UIBezierPath!
    private var previousPoint: CGPoint = CGPoint.zero
    private var isHaveDraw: Bool = false
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        self.currentPointArr = NSMutableArray.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        self.currentPointArr = NSMutableArray.init()
    }
    
    func commonInit() {
        path = UIBezierPath.init()
        path.lineWidth = 2
        
        min = 0
        max = 0
        
        let pan: UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panAction(_:)))
        
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        self.addGestureRecognizer(pan)
    }
    
    //MARK: public Action
    
    //清除
    public func clear() {
        if (self.currentPointArr != nil) && self.currentPointArr!.count > 0 {
            self.currentPointArr?.removeAllObjects()
        }
        self.hasSignatureImg = false
        max = 0
        min = 0
        path = UIBezierPath.init()
        path.lineWidth = 2
        isHaveDraw = false
        self.setNeedsDisplay()
    }
    //确定
    public func sure() {
        isSure = true
        self.setNeedsDisplay()
        return imageRepresentation()
        
    }
    
    //MARK:图片处理
    
    //对图片进行处理，包括剪裁和倍数处理。imageBlackToTransparent->cutImage->scaleToSize
    func imageRepresentation () {
        //UIGraphicsBeginImageContext(self.bounds.size)
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        image = imageBlackToTransparent(image: image)
    
        print("the origin image width is \(image.size.width) and height is \(image.size.height) ")
        let img = cutImage(image)
        let imgScaled = scaleToSize(img)
        self.signatureImg = imgScaled
    }
    
    //遍历图片，将黑色像素变成透明像素
    func imageBlackToTransparent(image: UIImage) -> UIImage {
        //分配内存
        let imageWidth: Int =  Int(image.size.width)
        let imageHeight: Int = Int(image.size.height)
        let bytesPerRow: size_t = imageWidth * 4
        let rgbImageBuf = UnsafeMutablePointer<UInt32>.allocate(capacity: bytesPerRow * imageHeight)
        let bitmapInfo = CGBitmapInfo.init(rawValue: UInt32(UInt32(CGImageByteOrderInfo.order32Little.rawValue) | UInt32(CGImageAlphaInfo.noneSkipLast.rawValue)))
        
        //创建context
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let context: CGContext = CGContext(data: rgbImageBuf, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        /*'CGContextDrawImage' is unavailable: Use draw(_in:)
        CGContextDrawImage(context, CGRect.init(x: 0, y: 0, width: imageWidth, height: imageHeight), image.cgImage)*/
        context.draw(image.cgImage!, in: CGRect.init(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        //遍历像素
        let pixelNum = imageWidth * imageHeight
        var pCurPtr = rgbImageBuf
        
        for _ in 0..<pixelNum {
            pCurPtr += 1
           //黑色变透明
            if pCurPtr.pointee == 0xffffff {
                let  ptr = pCurPtr
                ptr[0] = 0
            }
        }
        
        //内存转换成image
        let dataProvider = CGDataProvider.init(dataInfo: nil, data: rgbImageBuf, size: imageWidth * imageHeight, releaseData: { (dataInfo, data, size) in
            
        })
        
        let imageRef = CGImage.init(width: imageWidth, height: imageHeight, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        
        let resultImage: UIImage = UIImage.init(cgImage: imageRef!)
        return resultImage
    }
    

    //image剪裁，包括水印处理
    @discardableResult
    func cutImage(_ image: UIImage) -> UIImage {
        var rect: CGRect!
        if min == 0 && max == 0 {
            rect = CGRect.init(x: 0, y: 0, width: 0, height: 0)
        } else {
            rect = CGRect.init(x: min - 3 , y: 0, width: max - min + 6, height: self.frame.size.height)
        }
        print("the rect is \(rect)")
        let imageRef: CGImage = (image.cgImage?.cropping(to: rect))!
        let img: UIImage = UIImage.init(cgImage: imageRef )
        let lastImage = addText(img, markText: self.showMessage)
        
        self.setNeedsDisplay()
        return lastImage
    }
    
    //添加水印
    func addText(_ img: UIImage, markText: String) -> UIImage {
        let w: CGFloat = img.size.width
        let h: CGFloat = img.size.height
        
        var size: CGFloat = 20
        var textFont: UIFont = UIFont.systemFont(ofSize: size)
        var fontAttribute = [NSAttributedStringKey.font: textFont]
        let mark = NSString.init(string: markText)
        
//        let options = UInt8(NSStringDrawingOptions.usesFontLeading.rawValue) | UInt8(NSStringDrawingOptions.truncatesLastVisibleLine.rawValue) | UInt8(NSStringDrawingOptions.usesFontLeading.rawValue)

        let options: NSStringDrawingOptions = [NSStringDrawingOptions.usesFontLeading, NSStringDrawingOptions.truncatesLastVisibleLine, NSStringDrawingOptions.usesLineFragmentOrigin,NSStringDrawingOptions.usesDeviceMetrics]
        
        var sizeOfText  = mark.boundingRect(with: CGSize.init(width: 128, height: 30), options: options, attributes: fontAttribute, context: nil)
        
        if w < sizeOfText.width { //w <sizeOfText
            while sizeOfText.width > w { //不断缩减size
                size -= 1
                textFont = UIFont.systemFont(ofSize: size)
                fontAttribute = [NSAttributedStringKey.font: textFont]
                sizeOfText = mark.boundingRect(with: CGSize.init(width: 128, height: 30), options: options, attributes: fontAttribute, context: nil)
            }
        } else {
            size = 45
            textFont = UIFont.systemFont(ofSize: size)
            sizeOfText = mark.boundingRect(with: CGSize.init(width: self.frame.size.width, height: 30), options: options, attributes: fontAttribute, context: nil)
            while sizeOfText.width > w {
                size += 1
                textFont = UIFont.systemFont(ofSize: size)
                fontAttribute = [NSAttributedStringKey.font: textFont]
                sizeOfText = mark.boundingRect(with: CGSize.init(width: self.frame.size.width, height: 30), options: options, attributes: fontAttribute, context: nil)
                
            }
        }
        
        //
        UIGraphicsBeginImageContext(img.size)
        UIColor.red.set()
        let atttibute = [NSAttributedStringKey.font: textFont]
        img.draw(in: CGRect.init(x: 0, y: 0, width: w, height: h))
        mark.draw(in: CGRect.init(x: (w - sizeOfText.width) / 2, y: (h - sizeOfText.height) / 2, width: sizeOfText.width , height: sizeOfText.height), withAttributes: atttibute)
        let aImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return aImg!
    }
    
    //调整尺寸
    func scaleToSize(_ image: UIImage) -> UIImage {
        var rect: CGRect!
        let imageWidth = image.size.width
        if imageWidth >= 128 {
            rect = CGRect.init(x: 0, y: 0, width: 128, height: self.frame.size.height)
        } else {
            rect = CGRect.init(x: 0, y: 0, width: image.size.width, height: self.frame.size.height)
        }
        let size: CGSize = rect.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: rect)
        let scaleImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.setNeedsDisplay()
        return scaleImage
    }
    
    //MARK: 手势处理
    
    @objc func panAction(_ pan: UIPanGestureRecognizer) {
        let currentPoint: CGPoint = pan.location(in: self)
        let midPoint: CGPoint = midpoint(p0: previousPoint, p1: currentPoint)
       // print("触摸点位置--currentPoint\(currentPoint)")
        self.currentPointArr?.add(NSValue.init(cgPoint: currentPoint))
        self.hasSignatureImg = true
        let viewHeight = self.frame.size.height
        let currentY = currentPoint.y
        
        
        if pan.state == .began {
            path.move(to: currentPoint)
        } else if pan.state == .changed  {
            path.addQuadCurve(to: midPoint, controlPoint: previousPoint)
        }
        
        if 0 <= currentY && currentY <= viewHeight {
            if max == 0 && min == 0 {
                max = currentPoint.x
                min = currentPoint.x
            } else {
                if max <= currentPoint.x {
                    max = currentPoint.x
                }
                if currentPoint.x <= min {
                    min = currentPoint.x
                }
            }
        }
        previousPoint = currentPoint
        self.setNeedsDisplay()
        isHaveDraw = true
        if self.delegate != nil   {
            self.delegate?.onSignatureWriteAction()
        }
        
    }
    
    //MARK: 重新绘制
    public override func draw(_ rect: CGRect) {
//        super.draw(rect)
        self.backgroundColor = UIColor.white
        UIColor.red.setStroke()
        path.stroke()
        
        let context: CGContext = UIGraphicsGetCurrentContext()!
        
        if !isSure && !isHaveDraw {
            let str: NSString = "此处手写签名,正楷，工整书写"
            context.setFillColor(red: 199/255.0, green: 199/255.0, blue: 199/255.0, alpha: 1.0)
            let rect1 = CGRect.init(x: (rect.size.width - strWidth) / 2.0  , y: (rect.size.height - strHeight) / 3.0 - 5, width: strWidth, height: strHeight)
            origionX = rect1.origin.x
            totoalWidth = rect1.origin.x + strWidth
            let fontAttribute  =  [NSAttributedStringKey.font:  UIFont.systemFont(ofSize: 15)]
            str.draw(in: rect1, withAttributes: fontAttribute)
        } else {
            isSure = false
        }
    }
    
    func clearPan() {
        path = UIBezierPath.init()
        path.lineWidth = 3
        self.setNeedsDisplay()
    }
    
}
