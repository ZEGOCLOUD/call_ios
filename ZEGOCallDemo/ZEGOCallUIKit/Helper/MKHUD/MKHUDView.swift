//
//  MKHUD.swift
//  MKHUD
//
//  Created by Jacky on 2021/5/23.
//

import UIKit

fileprivate let MKHUD_DefaultCorner: CGFloat = 5.0
fileprivate let MKHUD_MinWidth: CGFloat = 42.0
fileprivate let MKHUD_MinOuterMargin: CGFloat = 20.0
fileprivate let MKHUD_DefaultContentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
fileprivate let MKHUD_DefaultItemSpacing: CGFloat = 8.0
fileprivate let MKHUD_DefaultRoundProgressSize: CGSize = CGSize(width: 37, height: 37)
fileprivate let MKHUD_DefaultBarProgressSize: CGSize = CGSize(width: 128, height: 10)


public final class MKHUDView: UIView {
    
    private lazy var backgroundView: MKHUDBackgroundView = {
        let v = MKHUDBackgroundView()
        v.color = self.theme.backgroundColor
        v.layer.cornerRadius = MKHUD_DefaultCorner
        v.layer.masksToBounds = true
        return v
    }()
    
    private lazy var contentView: UIView = {
        let v = MKHUDBackgroundView()
        v.color = .clear
        return v
    }()
    
    private let topLine: UIView = UIView() //for easy layout
    
    public private(set) lazy var textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.backgroundColor = .clear
        l.textColor = self.theme.frontgroundColor
        l.textAlignment = .center
        return l
    }()
    
    public private(set) lazy var detailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.backgroundColor = .clear
        l.textColor = self.theme.frontgroundColor
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()
    
    private(set) lazy var button: MKHUDButton = {
        let btn = MKHUDButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        btn.setTitleColor(theme.frontgroundColor, for: .normal)
        btn.addTarget(self, action: #selector(onClickButton), for: .touchUpInside)
        return btn
    }()
    
    private lazy var circleProgressView: MKRoundProgressView = {
        let rp = MKRoundProgressView()
        rp.trackColor = theme.frontgroundColor.withAlphaComponent(0.2)
        rp.progressbarColor = theme.frontgroundColor
        return rp
    }()
    
    private lazy var barProgressView: MKBarProgressView = {
        let bar = MKBarProgressView()
        bar.progressbarColor = theme.frontgroundColor
        return bar
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        var ai: UIActivityIndicatorView!
        if #available(iOS 13.0, *) {
            ai = UIActivityIndicatorView(style: .whiteLarge)
        } else {
            ai = UIActivityIndicatorView(style: .white)
        }
        ai.color = theme.frontgroundColor
        ai.hidesWhenStopped = true
        return ai
    }()
    
    public var backgroundStyle: MKHUDBackgroundStyle = .solid {
        didSet {
            backgroundView.style = backgroundStyle
        }
    }
    
    /// UIEdgeInsets(.right is invalid)
    public var insets: UIEdgeInsets = MKHUD_DefaultContentInsets {
        didSet {
            remarkConstraints()
        }
    }
    
    public var spacing: CGFloat = MKHUD_DefaultItemSpacing {
        didSet {
            remarkConstraints()
        }
    }
    
    public var suqared: Bool = false {
        didSet {
            if suqared == oldValue {
                return
            }
            remarkConstraints()
        }
    }
    
    public var corner: CGFloat = MKHUD_DefaultCorner {
        didSet {
            backgroundView.layer.cornerRadius = corner
        }
    }
    
    public var customView: UIView? {
        didSet{
            if mode == .custom {
                remarkConstraints()
            }
        }
    }
    
    public var text: String = "" {
        didSet {
            textLabel.text = text
            remarkConstraints()
        }
    }
    
    public var detailText: String = "" {
        didSet {
            detailLabel.text = detailText
            remarkConstraints()
        }
    }
    
    public var btnConfig: MKHUDButtonConfig? {
        didSet {
            guard let config = btnConfig else {
                return
            }
            button.setTitle(config.title, for: .normal)
            remarkConstraints()
        }
    }
    
    public var mode: MKHUDMode = .text {
        didSet {
            if mode == oldValue {
                return
            }
            remarkConstraints()
        }
    }
    
    public var progress: Double = 0.0 {
        didSet {
            updateProgressIfNeed()
        }
    }
    
    public var minSize: CGSize? {
        didSet {
            remarkConstraints()
        }
    }
    
    public var autoHidden: TimeInterval = 0
    public var animationMode: MKHUDAnimationMode = .none
    public var completionHandle: MKHUDCompletionHandle?
    
    private let theme: MKHUDTheme!

    public init(frame: CGRect, theme: MKHUDTheme = .dark) {
        self.theme = theme
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    deinit {
//        print(">>>>>>deinit: \(self)")
//    }
    
    @objc func onClickButton() {
        guard let config = self.btnConfig else {
            return
        }
        config.action?(self)
    }
}

//MARK:setups
extension MKHUDView {
    
    // set up default values
    private func setup() {
        setupDefaults()
        setupSubviews()
        setupConstraints()
    }
    
    private func setupDefaults() {
    }
    
    private func setupSubviews() {
        setupBackgroundView()
    }
    
    private func setupConstraints() {
        remarkConstraints()
    }
    
    private func setupBackgroundView() {
        addSubview(backgroundView)
        var constraintsNeedRemove = [NSLayoutConstraint]()
        for cons in self.constraints {
            if cons.firstItem as? NSObject == backgroundView && cons.secondItem as? NSObject == self {
                constraintsNeedRemove.append(cons)
            }
        }
        self.removeConstraints(constraintsNeedRemove)
        
        self.addConstraints(
            [
                backgroundView.centerXAnchor.constraint(equalTo: self.leadingAnchor, constant: self.frame.width.half),
                backgroundView.centerYAnchor.constraint(equalTo: self.topAnchor, constant: self.frame.height.half),
            ]
        )
        backgroundView.addSubview(contentView)
    }
}

//MARK:updates
extension MKHUDView {
    private func remarkConstraints() {
        contentView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        var preItem: UIView = topLine
        contentView.addSubview(topLine)
        contentView.addConstraints(
            [
                topLine.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
                topLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                topLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                topLine.heightAnchor.constraint(equalToConstant: 0),
            ]
        )

        if mode == .indeterminate {
            indicator.startAnimating()
            preItem = indicator
        } else if mode == .determinate {
            preItem = circleProgressView
        } else if mode == .bar {
            preItem = barProgressView
        } else if mode == .custom, let cv = customView {
            preItem = cv
        }
        
        let maxContentWidth: CGFloat = self.frame.width - 2 * MKHUD_MinOuterMargin - self.insets.left - self.insets.right
        
        if preItem != topLine {
            contentView.addSubview(preItem)
            contentView.addConstraints(
                [
                    preItem.topAnchor.constraint(equalTo: topLine.bottomAnchor),
                    preItem.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    preItem.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: insets.left)
                ]
            )
            // Adapt for custom view
            if preItem == customView && !preItem.frame.equalTo(.zero) {
                if preItem.frame.width > maxContentWidth {
                    let ph = maxContentWidth * preItem.frame.height / preItem.frame.width
                    let pw = maxContentWidth
                    preItem.frame = CGRect(origin: .zero, size: CGSize(width: pw, height: ph))
                }
                contentView.addConstraints(
                    [
                        preItem.widthAnchor.constraint(equalToConstant: preItem.frame.width),
                        preItem.heightAnchor.constraint(equalToConstant: preItem.frame.height),
                    ]
                )
            }
        }
        
        var appendItems = [UIView]()
        if text.count > 0 {
            appendItems.append(textLabel)
            textLabel.preferredMaxLayoutWidth = maxContentWidth
        }
        if detailText.count > 0 {
            appendItems.append(detailLabel)
            detailLabel.preferredMaxLayoutWidth = maxContentWidth
        }
        if let _ = btnConfig {
            appendItems.append(button)
            button.titleLabel?.preferredMaxLayoutWidth = maxContentWidth - 20
        }
        
        for item in appendItems {
            contentView.addSubview(item)
            let spacing_top = preItem == topLine ? 0 : spacing
            contentView.addConstraints(
                [
                    item.topAnchor.constraint(equalTo: preItem.bottomAnchor, constant: spacing_top),
                    item.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                ]
            )
            contentView.addConstraint(item.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: insets.left))
            preItem = item
        }
        
        guard preItem != topLine else {
            return
        }
        
        contentView.addConstraint(preItem.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom))
        contentView.layoutIfNeeded()
        var bgSize: CGSize = contentView.frame.size
        
        if let minSize = self.minSize {
            bgSize.width = max(minSize.width, contentView.frame.width)
            bgSize.height = max(minSize.height, contentView.frame.height)
        }
        
        if self.suqared {
            let side = max(bgSize.width, bgSize.height)
            bgSize = CGSize(width: side, height: side)
        }
        
        backgroundView.removeConstraints(backgroundView.constraints)
        backgroundView.addConstraints(
            [
                // for backgroundView size
                backgroundView.widthAnchor.constraint(equalToConstant: bgSize.width),
                backgroundView.heightAnchor.constraint(equalToConstant: bgSize.height),
                // for contentView position
                contentView.centerXAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: bgSize.width.half),
                contentView.centerYAnchor.constraint(equalTo: backgroundView.topAnchor, constant: bgSize.height.half),
            ]
        )

    }
    
    private func updateProgressIfNeed() {
        let __progress = min(progress, 1.0)
        if mode == .determinate {
            circleProgressView.progress = __progress
        } else if mode == .bar {
            barProgressView.progress = __progress
        }
    }
}


//MARK:left cycle
extension MKHUDView {
    
    public func show(to tv: UIView?) {
        assert(Thread.current.isMainThread, "[MKHUDView] Warning: UI update operations must be performed on the main thread")
        guard let toview = tv else {
            return
        }
        toview.addSubview(self)
        
        if animationMode == .none {
            transform = CGAffineTransform.identity
        } else {
            self.layoutIfNeeded()
            
            let start_transform = animationMode == .zoomIn ? CGAffineTransform.init(scaleX: 0.5, y: 0.5) : CGAffineTransform.init(scaleX: 1.5, y: 1.5)
            self.backgroundView.transform = start_transform
            self.backgroundView.alpha = 0.0
            let animationClosure = {
                self.backgroundView.transform = CGAffineTransform.identity
                self.backgroundView.alpha = 1.0
            }
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: animationClosure)
        }
        
        if autoHidden > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoHidden) { [weak self] in
                self?.dismiss()
            }
        }
    }
    
    public func dismiss(animated: Bool = true) {
        assert(Thread.current.isMainThread, "[MKHUDView] Warning: UI update operations must be performed on the main thread")
        if animationMode == .none || animated == false {
            removeFromSuperview()
            completionHandle?()
            return
        }
        
        let finish_transform = animationMode == .zoomIn ? CGAffineTransform.init(scaleX: 0.5, y: 0.5) : CGAffineTransform.init(scaleX: 1.5, y: 1.5)
        let animationClosure = {
            self.backgroundView.transform = finish_transform
            self.backgroundView.alpha = 0.0
        }
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: animationClosure) { _ in
            self.removeFromSuperview()
            self.completionHandle?()
        }
    }
    
}

//MARK:get hub & hide it
extension MKHUDView {
    
    @discardableResult
    public class func HUDForView(view: UIView) -> MKHUDView? {
        for subv in view.subviews.reversed() {
            if let hud = subv as? MKHUDView {
                return hud
            }
        }
        return nil
    }
    
    @discardableResult
    public class func hideHUDForView(view: UIView, animated: Bool = true) -> Bool {
        if let hud = self.HUDForView(view: view) {
            hud.dismiss(animated: animated)
            return true
        }
        return false
    }

}

//MARK:UI Checker *** JUET FOR TEST ***
extension MKHUDView {
    
    public enum DisplayState: String {
        case full, becovered, hidden
    }
    
    public func checkUI() -> [DisplayState] {
        self.layoutIfNeeded()
        var checkNeededs: [UIView] = [textLabel, detailLabel, button, indicator, circleProgressView, barProgressView]
        if let customV = customView {
            checkNeededs.append(customV)
        }
        var result = [DisplayState]()
        checkNeededs.forEach{
            let state = isDisplayFull($0)
            result.append(state)
        }
        return result
    }
    
    private func isDisplayFull(_ view: UIView?) -> DisplayState {
        
        guard let v = view  else {
            return .hidden
        }
        
        if v.superview == nil || v.isHidden == true {
            return .hidden
        }
        
        if contentView.bounds.contains(v.frame) {
            return .full
        } else {
            return .becovered
        }
    }
}


class MKRoundProgressView: UIView {
    
    var trackColor: UIColor = .lightGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var progressbarColor: UIColor = .darkGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var progress: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: MKHUD_DefaultRoundProgressSize))
        setup()
        setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        return self.bounds.size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let content = UIGraphicsGetCurrentContext() else {
            return
        }
        let lineWidth: CGFloat = 3.0
        content.setLineWidth(lineWidth)
        content.setLineCap(.round)

        let radius = (frame.size.width - lineWidth) * 0.5
        content.addEllipse(in: CGRect(x: lineWidth * 0.5, y: lineWidth *
                                        0.5, width: 2 * radius, height: 2 * radius))
        content.setStrokeColor(trackColor.cgColor)
        content.strokePath()
        
        let p = min(progress, 1.0)
        content.addArc(center: CGPoint(x: frame.size.width * 0.5, y: frame.size.width * 0.5), radius: radius, startAngle: -CGFloat(Double.pi * 0.5), endAngle: CGFloat(p * Double.pi * 2 - Double.pi * 0.5), clockwise: false)
        content.setStrokeColor(progressbarColor.cgColor)
        content.strokePath()
    }
}

class MKBarProgressView: UIView {
    
    var progressbarColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var progress: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: MKHUD_DefaultBarProgressSize))
        setup()
        setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        return self.bounds.size
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let content = UIGraphicsGetCurrentContext() else {
            return
        }
        let lineWidth: CGFloat = 2.0
        content.setLineWidth(lineWidth)
        content.setLineCap(.round)
        
        let W = frame.size.width
        let H = frame.size.height
        let R = frame.size.height.half - lineWidth.half
        
        content.move(to: CGPoint(x: R + lineWidth.half, y: lineWidth.half))
        content.addLine(to: CGPoint(x: W - R - lineWidth.half, y: lineWidth.half))
        content.addArc(center: CGPoint(x: W - R - lineWidth.half, y: H.half), radius: R, startAngle: -CGFloat.pi.half, endAngle: CGFloat.pi.half, clockwise: false)
        content.addLine(to: CGPoint(x: R + lineWidth.half, y: H - lineWidth.half))
        content.addArc(center: CGPoint(x: R + lineWidth.half, y: H.half), radius: R, startAngle: CGFloat.pi.half, endAngle: CGFloat.pi.half * 3, clockwise: false)

        content.setStrokeColor(progressbarColor.cgColor)
        content.strokePath()
    
        let p = CGFloat(min(progress, 1.0))
        let SPC: CGFloat = 1.0
        let BW = W - lineWidth.dual - SPC.dual
        let BH = H - lineWidth.dual - SPC.dual
        let BR = BH.half
    
        let lp = min(p, BR / BW)
        let angle = CGFloat(acos(Double((BR - lp * BW) / BR)))
        content.addArc(center: CGPoint(x: lineWidth + SPC + BR, y: H.half), radius: BR, startAngle: CGFloat.pi - angle, endAngle: CGFloat.pi + angle, clockwise: false)
        content.closePath()
        
        if p > BR / BW {
            let cp = min(p - BR / BW, 1 - (BR / BW).dual)
            let cl = (BW - BR.dual) * cp / (1 - (BR / BW).dual)
            let co = lineWidth + SPC + BR
            content.move(to: CGPoint(x: co, y: lineWidth + SPC))
            content.addLine(to: CGPoint(x: co + cl, y: lineWidth + SPC))
            content.addLine(to: CGPoint(x: co + cl, y: H - lineWidth - SPC))
            content.addLine(to: CGPoint(x: co, y: H - lineWidth - SPC))
        }
        
        if p > 1 - BR / BW {
            let angle = CGFloat(acos((BR - (1 - p) * BW) / BR))
            content.move(to: CGPoint(x: W - lineWidth - SPC - BR, y: lineWidth + SPC))
            content.addArc(center: CGPoint(x: W - lineWidth - SPC - BR, y: H.half), radius: BR, startAngle: CGFloat.pi.half * 3, endAngle: CGFloat.pi.dual - angle, clockwise: false)
            
            content.move(to: CGPoint(x: W - lineWidth - SPC - BR, y: lineWidth + SPC))
            content.addLine(to: CGPoint(x: W - lineWidth - SPC - BR, y: H - lineWidth - SPC))
            content.addArc(center: CGPoint(x: W - lineWidth - SPC - BR, y: H.half), radius: BR, startAngle: CGFloat.pi.half, endAngle: angle, clockwise: true)
            
            let point = CGPoint(x: p * BW + lineWidth + SPC, y: H.half - sin(angle) * BR)
            content.addLine(to: point)
            
        }
        
        content.setFillColor(progressbarColor.cgColor)
        content.fillPath()
    }
}

class MKHUDButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1.0
        self.backgroundColor = .clear
        self.titleLabel?.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = bounds.height.half
    }
    
    override var intrinsicContentSize: CGSize {
        if self.title(for: .normal)?.count == 0 {
            return .zero
        }
        var size = super.intrinsicContentSize
        size.width += 20
        return size
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        self.layer.borderColor = color?.cgColor
    }
    
}


class MKHUDBackgroundView: UIView {
    
    var style: MKHUDBackgroundStyle = .solid {
        didSet {
            update()
        }
    }
    var color: UIColor = .clear {
        didSet {
            update()
        }
    }
    var effectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.clipsToBounds = true
        self.layer.allowsGroupOpacity = false
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func addSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        super.addSubview(view)
    }
    
    func removeSubitems() {
        self.subviews.filter { $0 != effectView }.forEach {
            $0.removeFromSuperview()
        }
    }
    
    private func update() {
        if style == .solid {
            effectView?.removeFromSuperview()
            effectView = nil
            self.backgroundColor = color
        } else if style == .blur {
            self.backgroundColor = .clear
            var effect: UIBlurEffect!
            if #available(iOS 13.0, *) {
                if self.color.darkLike() {
                    effect = UIBlurEffect(style: .systemThinMaterialDark)
                } else {
                    effect = UIBlurEffect(style: .systemThinMaterialLight)
                }
            } else {
                if self.color.darkLike() {
                    effect = UIBlurEffect(style: .dark)
                } else {
                    effect = UIBlurEffect(style: .light)
                }
            }
            let ev = UIVisualEffectView(effect: effect)
            self.addSubview(ev)
            self.addConstraints(
                [
                    ev.topAnchor.constraint(equalTo: self.topAnchor),
                    ev.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    ev.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    ev.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                ]
            )
            self.effectView = ev
        }
    }
}
