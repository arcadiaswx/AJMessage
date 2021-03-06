//
//  AJMessage.swift
//  AJMessage
//
//  Created by ajiejoy on 9/18/16.
//  Copyright © 2016 ajiejoy. All rights reserved.
//

import UIKit

public class AJMessage: UIView {

    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override public func draw(_ rect: CGRect) {
        // Drawing code
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8,height: 8))
        mainShape.frame = rect
        mainShape.path = path.cgPath
        mainShape.shadowColor = UIColor.black.cgColor
        mainShape.shadowOffset = CGSize(width: 1, height: 1)
        mainShape.shadowRadius = 15
        mainShape.shadowOpacity = 0.4
    }
 
    public enum Status {
        case error
        case info
        case success
    }
    
    public enum Position {
        case top
        case bottom
    }
    
    public typealias AJcompleteHandler = () -> Void
    
    private var message = UILabel()
    private var title = UILabel()
    private var action : AJcompleteHandler? = nil
    private var mainView = UIView()
    private var mainShape = CAShapeLayer()
    private var duration : Double?
    private var position : Position = .top
    private var iconView : UIImageView!
    private var timer : Timer? = nil
    private(set) var status : Status = .error
    private(set) var config : AJMessageConfig!
    
    init(title : NSAttributedString,message : NSAttributedString,duration: Double?, position: Position , status:Status ,config:AJMessageConfig) {
        let width = UIApplication.shared.keyWindow!.bounds.width - 16;
        
        var saveTop : CGFloat = 24
        if UIDevice.isHaveNotch, #available(iOS 11.0, *) {
            saveTop = UIApplication.shared.keyWindow!.safeAreaInsets.top
        }
        
        super.init(frame: CGRect(x: 8, y: saveTop , width: width, height: 10))
        self.config = config
        self.title.attributedText = title
        self.message.attributedText = message
        self.status = status
        self.duration = duration
        self.position = position
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(){
        backgroundColor = UIColor.clear
        
        mainView.frame = bounds
        mainView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        mainView.backgroundColor = UIColor.clear
        mainView.layer.addSublayer(mainShape)
        
        iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 8, y: 20, width: 30, height: 30)
        
        title.frame = CGRect(x: 46, y: 16, width: mainView.bounds.width - 16 , height: 1)
        title.numberOfLines = 0
        title.font = config.titleFont
        title.textColor = config.titleColor
        
        message.frame = CGRect(x: title.frame.minX, y: title.frame.maxY, width: mainView.bounds.width - 16 , height: 1)
        message.numberOfLines = 0
        message.font = config.messageFont
        message.textColor = config.messageColor
        
        addSubview(mainView)
        mainView.addSubview(iconView)
        mainView.addSubview(message)
        mainView.addSubview(title)
        
        let bundle = Bundle(for: type(of: self))
        let url = bundle.resourceURL!.appendingPathComponent("AJMessage.bundle")
        let resourceBundle = Bundle(url: url)
        
        switch status {
        case .info:
            mainShape.fillColor = UIColor(red: CGFloat(241.0/255.0), green: CGFloat(196.0/255.0), blue: CGFloat(15.0/255.0), alpha: 1).cgColor
            iconView.image = UIImage(named: "info", in: resourceBundle, compatibleWith: nil)
        case .error:
            mainShape.fillColor = UIColor(red: CGFloat(231.0/255.0), green: CGFloat(76.0/255.0), blue: CGFloat(60.0/255.0), alpha: 1).cgColor
            iconView.image = UIImage(named: "error", in: resourceBundle, compatibleWith: nil)
        case .success:
            mainShape.fillColor = UIColor(red: CGFloat(46.0/255.0), green: CGFloat(204.0/255.0), blue: CGFloat(113.0/255.0), alpha: 1).cgColor
            iconView.image = UIImage(named: "success", in: resourceBundle, compatibleWith: nil)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideMessages))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.onMoving(pan:)))
        addGestureRecognizer(pan)
        
        if let duration = duration {
            timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(self.hideMessages), userInfo: nil, repeats: false)
        }
        
        //remove all current messages
        for vim in UIApplication.shared.keyWindow!.subviews {
            if let msg = vim as? AJMessage {
                msg.hideMessages()
            }
        }
        UIApplication.shared.keyWindow?.addSubview(self)
        
        self.alpha = 0.1
        self.transform = CGAffineTransform(scaleX: 3, y: 3)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.alpha = 1
            self.transform = .identity
            }) { (B) in
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut,.beginFromCurrentState], animations: {
                    self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    }, completion: { (B) in
                        UIView.animate(withDuration: 0.2, animations: {
                            self.transform = .identity
                        })
                })
        }
        
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }
    
    func updateFrame(){
        let maxSize = CGSize(width: mainView.bounds.width - 62, height: CGFloat.greatestFiniteMagnitude)
        
        let sizeT = title.attributedText?.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil).size ?? .zero
        title.frame.size.height = sizeT.height
        let sizeM = message.attributedText?.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil).size ?? .zero
        message.frame.origin.y = title.frame.maxY + 4
        message.frame.size.height = sizeM.height
        self.frame.size.height = message.frame.maxY + 16
        
        if position == .bottom {
            var saveBottom : CGFloat = 16
            if UIDevice.isHaveNotch, #available(iOS 11.0, *) {
                saveBottom = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
            }
            self.frame.origin.y = UIApplication.shared.keyWindow!.bounds.height - saveBottom - self.frame.size.height
        }
    }
    
    @objc func hideMessages(){
        
        UIView.transition(with: self, duration: 0.3, options: [.transitionCrossDissolve ,.curveEaseInOut,.beginFromCurrentState]
            , animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { (B) in
                self.removeFromSuperview()
                self.action?()
        }
        
    }
    
    @objc func onMoving(pan: UIPanGestureRecognizer){
//        let velo = pan.velocity(in: UIApplication.shared.keyWindow!)
        let point = pan.translation(in: UIApplication.shared.keyWindow!)
        
        if pan.state == .began {
            timer?.invalidate()
        }else if pan.state == .changed {
            let alpha = min(1 - (point.x/150.0),1 - (point.y/150.0))
            
            self.alpha = alpha
            self.transform = CGAffineTransform(translationX: point.x, y: point.y)
            if alpha <= 0 {
                self.removeFromSuperview()
            }
            
        }else if pan.state == .ended {
            self.alpha = 1
            UIView.animate(withDuration: 0.4, animations: {
                self.transform = .identity
            })
            
            if let duration = duration {
                timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(self.hideMessages), userInfo: nil, repeats: false)
            }
        }
    }
    
    public func onHide(_ sender : @escaping AJcompleteHandler){
        action = sender
    }
    
    /// show AJMessage Nb:duration = nil to infinite, default is 3
    ///
    /// - Parameters:
    ///   - title: String of title
    ///   - message: String of message
    ///   - duration: Optional duration, default value is 3.0
    ///   - position: Optional Position, default value is .top
    ///   - status: Optional status, default value is .success
    ///   - config: Optional config, default is using AJMessageConfig.shared
    /// - Returns: AJMessage for chaining function like onhide
    @discardableResult public static func show(title : String,message : String,duration: Double? = 3.0 , position: Position = .top,status : Status = .success ,config:AJMessageConfig = AJMessageConfig.shared) -> AJMessage {
        let attrTitle = NSAttributedString(string: title, attributes: [.font:config.titleFont,.foregroundColor:config.titleColor])
        
        let attrMessage = NSAttributedString(string: message, attributes: [.font:config.messageFont,.foregroundColor:config.messageColor])
        
        let msg = AJMessage(title: attrTitle, message: attrMessage, duration: duration, position: position, status: status, config:config)
        return msg
    }
    
    /// show AJMessage Nb:duration = nil to infinite, default is 3
    ///
    /// - Parameters:
    ///   - title: NSAttributedString of title
    ///   - message: NSAttributedString of message
    ///   - duration: Optional duration, default value is 3.0
    ///   - position: Optional Position, default value is .top
    ///   - status: Optional status, default value is .success
    /// - Returns: AJMessage for chaining function like onhide
    @discardableResult public static func show(title : NSAttributedString,message : NSAttributedString,duration: Double? = 3.0 , position: Position = .top,status : Status = .success) -> AJMessage {
        let msg = AJMessage(title: title, message: message, duration: duration, position: position, status: status, config:AJMessageConfig.shared)
        return msg
    }
    
    /** hide all AJMessage class */
    public static func hide(){
        for vim in UIApplication.shared.keyWindow!.subviews {
            if let msg = vim as? AJMessage {
                msg.hideMessages()
            }
        }
    }
    
}
