//
//  PopSignatureView.swift
//  SwiftTestDemo
//
//  Created by zhengxh on 2017/11/13.
//  Copyright © 2017年 zhengxh. All rights reserved.
//

import Foundation
import UIKit

let ScreenWidth  = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height
let SignatureViewHeight = (ScreenWidth  * 350 / 375.0)

let ActionSheetBackgroundColor: UIColor = UIColor.init(red: 106/255 , green: 106/255 , blue: 106/255, alpha: 0.8)
let WindowColor: UIColor = UIColor.init(red: 106/255 , green: 106/255 , blue: 106/255, alpha: 0.8)
let BackGroundColor: UIColor = UIColor.init(red: 0/255 , green: 0/255 , blue: 0/255, alpha: 0.4)

public func colorRGB(_ R: CGFloat, _ G: CGFloat, _ B: CGFloat) -> UIColor {
    return UIColor.init(red: R, green: G, blue: B, alpha: 1.0)
}

//MARK: Protocol
public protocol PopSignatureProtocol {
    func onSubmit(signatureImg: UIImage)
}

public class PopSignatureView: UIView,SignatureViewProtocol {
   
    var maskViewButton: UIButton! //遮罩页面
    var signatureView: EasySignatureView!//签名页面
    var btnCommit: UIButton!//提交按钮
    var backGroundView: UIView!//背景页面
    var delegateSignatur: PopSignatureProtocol?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        self.backgroundColor = WindowColor
        self.isUserInteractionEnabled = true
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView(){
        maskViewButton = UIButton.init(type: .custom)
        maskViewButton.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        maskViewButton.backgroundColor = BackGroundColor
        maskViewButton.isUserInteractionEnabled = true
        maskViewButton.addTarget(self, action: #selector(maskViewTap), for: UIControlEvents.touchUpInside)
        self.addSubview(maskViewButton)
        
        backGroundView = UIView.init(frame: CGRect.init(x: 0, y: ScreenHeight, width: ScreenWidth, height: 0))
        backGroundView.isUserInteractionEnabled = true
        maskViewButton.addSubview(backGroundView)
        
        let headView: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 44))
        headView.backgroundColor = UIColor.white
        backGroundView.addSubview(headView)
        
        let titleLabel: UILabel = UILabel.init(frame: CGRect.init(x: 60, y: 0, width: ScreenWidth - 120, height: 44))
        titleLabel.backgroundColor = UIColor.white
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        titleLabel.text = "签名"
        headView.addSubview(titleLabel)
        
        let clearBtn = UIButton.init(type: .custom)
        clearBtn.frame = CGRect.init(x: ScreenWidth - 60, y: 0, width: 60, height: 44)
        clearBtn.backgroundColor = UIColor.white
        clearBtn.setTitle("清除", for: UIControlState.normal)
        clearBtn.setTitleColor(UIColor.black, for: UIControlState.normal)
        clearBtn.addTarget(self, action: #selector(clearSignature), for: UIControlEvents.touchUpInside)
        headView.addSubview(clearBtn)
        
        let separateView: UIView = UIView.init(frame: CGRect.init(x: 0, y: 45, width: ScreenWidth, height: 1))
        separateView.backgroundColor = UIColor.green
        backGroundView.addSubview(separateView)
        
        
        signatureView = EasySignatureView.init(frame: CGRect.init(x: 0, y: 46, width: ScreenWidth, height: SignatureViewHeight - 46))
        signatureView.showMessage = ""
        signatureView.backgroundColor = UIColor.white
        backGroundView.addSubview(signatureView)
        
        btnCommit = UIButton.init(type: .custom)
        btnCommit.frame = CGRect.init(x: 0, y: SignatureViewHeight - 44, width: ScreenWidth, height: 44)
        btnCommit.backgroundColor = UIColor.red
        btnCommit.setTitleColor(UIColor.white, for: UIControlState.normal)
        btnCommit.setTitle("提交", for: UIControlState.normal)
        btnCommit.addTarget(self, action: #selector(commitBtnClick), for: UIControlEvents.touchUpInside)
        backGroundView.addSubview(btnCommit)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.backGroundView.frame = CGRect.init(x: 0, y: ScreenHeight - SignatureViewHeight, width: ScreenWidth, height: SignatureViewHeight)
            print("the width is \(self.backGroundView.bounds.size.width)")
            print("the height is \(self.backGroundView.bounds.size.height)")
        }, completion: nil)
    }
    
    //MARK: API Public  Method
    public func showView() {
        UIApplication.shared.keyWindow?.addSubview(self)
    }
    
    public func hideView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backGroundView.frame = CGRect.init(x: 0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight)
            self.alpha = 0
        }, completion: {(finished) in
            self.removeFromSuperview()
        })
    }
    
    //MARK: Protocol
    public func getSignatureImg(image: UIImage) {
        
    }
    
    public func onSignatureWriteAction() {
        
    }
    
    
    //MARK: BtnClick
    @objc func maskViewTap() {
        hideView()
    }
    @objc func clearSignature() {
        signatureView.clear()
        btnCommit.setTitleColor(colorRGB(255.0, 255.0, 255.0), for: UIControlState.normal)
        
    }
    @objc func commitBtnClick() {
        signatureView.sure()
        if signatureView.signatureImg != nil {
            print("hasImg")
            self.isHidden = true
            if delegateSignatur != nil {
                print("the image size is \(String(describing: signatureView.signatureImg?.size))")
                delegateSignatur!.onSubmit(signatureImg: signatureView.signatureImg!)
            }
        } else {
            print("no image")
        }
    }
}
