//
//  FlagPhoneNumberTextField.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import Foundation
import libPhoneNumber_iOS

open class FPNTextField: UITextField, UITextFieldDelegate, FPNCountryPickerDelegate, FPNDelegate {

	public var flagPhoneNumberDelegate: FPNTextFieldDelegate?

	/// The size of the flag
	public var flagSize: CGSize = CGSize(width: 32, height: 32) {
		didSet {
			layoutSubviews()
		}
	}
	
	/// The edges insets of the flag button
	public var flagButtonEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5) {
		didSet {
			layoutSubviews()
		}
	}
	
	/// The size of the leftView
	private var leftViewSize: CGSize {
		let width = leftViewLeftMargin + flagSize.width + flagButtonEdgeInsets.left + flagButtonEdgeInsets.right + phoneCodeTextField.frame.width + leftViewRightMargin
		let height = bounds.height

		return CGSize(width: width, height: height)
	}

	public var phoneCodeTextField: UITextField = UITextField()
	public lazy var countryPicker: FPNCountryPicker = FPNCountryPicker()
	private lazy var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
	private var nbPhoneNumber: NBPhoneNumber?
	private var formatter: NBAsYouTypeFormatter?
	
	var flagButton: UIButton = UIButton()

	open override var font: UIFont? {
		didSet {
			phoneCodeTextField.font = font
		}
	}
	
	open override var textColor: UIColor? {
		didSet {
			phoneCodeTextField.textColor = textColor
		}
	}

	/// Present in the placeholder an example of a phone number according to the selected country code.
	/// If false, you can set your own placeholder. Set to true by default.
	public var hasPhoneNumberExample: Bool = true {
		didSet {
			if hasPhoneNumberExample == false {
				placeholder = nil
			}
			updatePlaceholder()
		}
	}

	var selectedCountry: FPNCountry? {
		didSet {
			updateUI()
		}
	}


	/// If set, a search button appears in the picker inputAccessoryView to present a country search view controller
	public var parentViewController: UIViewController?
	
	/// Input Accessory View for the texfield
	public var textFieldInputAccessoryView: UIView?

    // MARK: - init
	
	init() {
		super.init(frame: .zero)
		
		setup()
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		setup()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setup()
	}
	
	deinit {
		parentViewController = nil
	}
    
    // MARK: - layout
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		leftView?.frame = leftViewRect(forBounds: frame)
		flagButton.imageEdgeInsets = flagButtonEdgeInsets
        updateLeftViewConstraints()
	}
	
	open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
		let width: CGFloat = min(bounds.size.width, leftViewSize.width)
		let height: CGFloat = min(bounds.size.height, leftViewSize.height)
		let rect: CGRect = CGRect(x: 0, y: 0, width: width, height: height)

		return rect
	}
	
	private func setup() {
		setupFlagButton()
		setupPhoneCodeTextField()
		setupLeftView()
        updateLeftViewConstraints()
		setupCountryPicker()

		autocorrectionType = .no
		addTarget(self, action: #selector(didEditText), for: .editingChanged)
		addTarget(self, action: #selector(displayNumberKeyBoard), for: .touchDown)
		delegate = self
	}
	
	private func setupFlagButton() {
		flagButton.contentHorizontalAlignment = .fill
		flagButton.contentVerticalAlignment = .fill
		flagButton.imageView?.contentMode = .scaleAspectFit
		flagButton.accessibilityLabel = "flagButton"
		flagButton.addTarget(self, action: #selector(displayCountryKeyboard), for: .touchUpInside)
		flagButton.translatesAutoresizingMaskIntoConstraints = false
		flagButton.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)
	}
	
	private func setupPhoneCodeTextField() {
		phoneCodeTextField.isUserInteractionEnabled = false
		phoneCodeTextField.translatesAutoresizingMaskIntoConstraints = false
		phoneCodeTextField.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
	}
	
	private func setupLeftView() {
		leftViewMode = UITextFieldViewMode.always
		leftView = UIView()
		leftView?.addSubview(flagButton)
		leftView?.addSubview(phoneCodeTextField)
	}
    
    private var leftViewHorizontalConstraints: [NSLayoutConstraint] = []
    private var leftViewVerticalConstraints: [[NSLayoutConstraint]] = []
    
    private func updateLeftViewConstraints() {
        
        if leftViewHorizontalConstraints.count > 0 {
            leftView?.removeConstraints(leftViewHorizontalConstraints)
        }
        for constraints in leftViewVerticalConstraints {
            leftView?.removeConstraints(constraints)
        }
        leftViewVerticalConstraints.removeAll()
        
        let views = ["flag": flagButton, "textField": phoneCodeTextField]
        leftViewHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(leftViewLeftMargin)-[flag]-(0)-[textField]-\(leftViewRightMargin)-|", options: [], metrics: nil, views: views)
        leftView?.addConstraints(leftViewHorizontalConstraints)
        
        for key in views.keys {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(key)]|", options: [], metrics: nil, views: views)
            leftView?.addConstraints(constraints)
            leftViewVerticalConstraints.append(constraints)
        }

    }
	
	private func setupCountryPicker() {
		countryPicker.countryPickerDelegate = self
		countryPicker.showPhoneNumbers = true
		countryPicker.backgroundColor = .white
		countryPicker.setCountry(Locale.current.regionCode!)
	}
	
	@objc private func displayNumberKeyBoard() {
		keyboardType = .numberPad
		inputView = nil
		inputAccessoryView = textFieldInputAccessoryView
		tintColor = .gray
		reloadInputViews()
	}
	
	@objc private func displayCountryKeyboard() {
		inputView = countryPicker
		inputAccessoryView = getToolBar(with: getCountryListBarButtonItems())
		tintColor = .clear
		reloadInputViews()
		becomeFirstResponder()
	}
	
	@objc private func displayAlphabeticKeyBoard() {
		showSearchController()
	}
	
	@objc private func resetKeyBoard() {
		keyboardType = .default
		inputView = nil
		inputAccessoryView = nil
		resignFirstResponder()
	}
	
    // MARK: - margin
    
    public var textLeftMargin: CGFloat = 8.0
    public var textRightMargin: CGFloat = 8.0
    
    override open func textRect( forBounds bounds: CGRect ) -> CGRect {
        let leftViewW = self.leftViewSize.width
        var inset: CGRect = CGRect(x: bounds.origin.x + self.textLeftMargin + leftViewW, y: bounds.origin.y, width: bounds.size.width - leftViewW - self.textLeftMargin - self.textRightMargin, height: bounds.size.height)
        return inset
    }
    
    override open func editingRect( forBounds bounds: CGRect ) -> CGRect {
        let leftViewW = self.leftViewSize.width
        var inset: CGRect = CGRect(x: bounds.origin.x + self.textLeftMargin + leftViewW, y: bounds.origin.y, width: bounds.size.width - leftViewW - self.textLeftMargin - self.textRightMargin, height: bounds.size.height)
        return inset
    }
    
    public var leftViewLeftMargin: CGFloat = 0.0 {
        didSet(newValue) {
            layoutSubviews()
        }
    }
    public var leftViewRightMargin: CGFloat = 0.0 {
        didSet(newValue) {
            layoutSubviews()
        }
    }
    
    
    // MARK: - Public

	/// Set the country image according to country code. Example "FR"
	public func setFlag(for regionCode: String) {
		countryPicker.setCountry(regionCode)
	}

	/// Get the current formatted phone number
	public func getFormattedPhoneNumber(format: FPNFormat) -> String? {
		return try? phoneUtil.format(nbPhoneNumber, numberFormat: convert(format: format))
	}

	/// Get the current raw phone number
	public func getRawPhoneNumber() -> String? {
		let phoneNumber = getFormattedPhoneNumber(format: .E164)
		var nationalNumber: NSString?

		phoneUtil.extractCountryCode(phoneNumber, nationalNumber: &nationalNumber)

		return nationalNumber as String?
	}

	/// Set directly the phone number. e.g "+33612345678"
	public func set(phoneNumber: String) {
		let cleanedPhoneNumber: String = clean(string: phoneNumber)

		if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
			if validPhoneNumber.italianLeadingZero {
				text = "0\(validPhoneNumber.nationalNumber.stringValue)"
			} else {
				text = validPhoneNumber.nationalNumber.stringValue
			}
			setFlag(for: phoneUtil.getRegionCode(for: validPhoneNumber))
		}
	}

	// Private

	@objc private func didEditText() {
		if let phoneCode = selectedCountry?.phoneCode, let number = text {
			var cleanedPhoneNumber = clean(string: "\(phoneCode) \(number)")

			if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
				nbPhoneNumber = validPhoneNumber

				cleanedPhoneNumber = "+\(validPhoneNumber.countryCode.stringValue)\(validPhoneNumber.nationalNumber.stringValue)"

				if let inputString = formatter?.inputString(cleanedPhoneNumber) {
					text = remove(dialCode: phoneCode, in: inputString)
				}
				flagPhoneNumberDelegate?.didValidatePhoneNumber(textField: self, isValid: true)
			} else {
				nbPhoneNumber = nil

				if let dialCode = selectedCountry?.phoneCode {
					if let inputString = formatter?.inputString(cleanedPhoneNumber) {
						text = remove(dialCode: dialCode, in: inputString)
					}
				}
				flagPhoneNumberDelegate?.didValidatePhoneNumber(textField: self, isValid: false)
			}
		}
	}

	private func convert(format: FPNFormat) -> NBEPhoneNumberFormat {
		switch format {
		case .E164:
			return NBEPhoneNumberFormat.E164
		case .International:
			return NBEPhoneNumberFormat.INTERNATIONAL
		case .National:
			return NBEPhoneNumberFormat.NATIONAL
		case .RFC3966:
			return NBEPhoneNumberFormat.RFC3966
		}
	}

	private func updateUI() {
		if let countryCode = selectedCountry?.code {
			formatter = NBAsYouTypeFormatter(regionCode: countryCode)
		}

		flagButton.setImage(selectedCountry?.flag, for: .normal)

		if let phoneCode = selectedCountry?.phoneCode {
			phoneCodeTextField.text = phoneCode
			phoneCodeTextField.sizeToFit()
			layoutSubviews()
		}

		if hasPhoneNumberExample == true {
			updatePlaceholder()
		}
		didEditText()
	}

	private func clean(string: String) -> String {
		var allowedCharactersSet = CharacterSet.decimalDigits

		allowedCharactersSet.insert("+")

		return string.components(separatedBy: allowedCharactersSet.inverted).joined(separator: "")
	}

	private func getValidNumber(phoneNumber: String) -> NBPhoneNumber? {
		guard let countryCode = selectedCountry?.code else { return nil }

		do {
			let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: countryCode)
			let isValid = phoneUtil.isValidNumber(parsedPhoneNumber)

			return isValid ? parsedPhoneNumber : nil
		} catch _ {
			return nil
		}
	}
	
	private func remove(dialCode: String, in phoneNumber: String) -> String {
		return phoneNumber.replacingOccurrences(of: "\(dialCode) ", with: "").replacingOccurrences(of: "\(dialCode)", with: "")
	}

	private func showSearchController() {
		if let countries = countryPicker.countries {
			let searchCountryViewController = FPNSearchCountryViewController(countries: countries)
			let navigationViewController = UINavigationController(rootViewController: searchCountryViewController)
			
			searchCountryViewController.delegate = self
			
			parentViewController?.present(navigationViewController, animated: true, completion: nil)
		}
	}
	
	private func getToolBar(with items: [UIBarButtonItem]) -> UIToolbar {
		let toolbar: UIToolbar = UIToolbar()

		toolbar.barStyle = UIBarStyle.default
		toolbar.items = items
		toolbar.sizeToFit()
		
		return toolbar
	}

	private func getCountryListBarButtonItems() -> [UIBarButtonItem] {
		let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
		let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(resetKeyBoard))
		
		doneButton.accessibilityLabel = "doneButton"
		
		if parentViewController != nil {
			let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.search, target: self, action: #selector(displayAlphabeticKeyBoard))
			
			searchButton.accessibilityLabel = "searchButton"
			
			return [searchButton, space, doneButton]
		}
		return [space, doneButton]
	}

	private func updatePlaceholder() {
		if let countryCode = selectedCountry?.code {
			do {
				let example = try phoneUtil.getExampleNumber(countryCode)
				let phoneNumber = "+\(example.countryCode.stringValue)\(example.nationalNumber.stringValue)"

				if let inputString = formatter?.inputString(phoneNumber) {
					placeholder = remove(dialCode: "+\(example.countryCode.stringValue)", in: inputString)
				} else {
					placeholder = nil
				}
			} catch _ {
				placeholder = nil
			}
		} else {
			placeholder = nil
		}
	}
	
	// - FPNCountryPickerDelegate

	func countryPhoneCodePicker(_ picker: FPNCountryPicker, didSelectCountry country: FPNCountry) {
		if let name = country.name, let dialCode = country.phoneCode, let code = country.code {
			flagPhoneNumberDelegate?.didSelectCountry(name: name, dialCode: dialCode, code: code)
		}
		selectedCountry = country
	}

	// - FPNTextFieldDelegate
	
	internal func didSelect(country: FPNCountry) {
		setFlag(for: country.code!)
	}
}
