//
//  CreatRequestPreView.swift
//  Desk360
//
//  Created by samet on 28.10.2019.
//

import UIKit

final class CreatRequestPreView: UIView, Layoutable {

	internal lazy var titleLabel: UILabel = {
		let label = UILabel()
		label.numberOfLines = 3
		label.textAlignment = .center
		label.font = Desk360.Config.Requests.Listing.Placeholder.Title.font
		label.textColor = Desk360.Config.currentTheme.listingPlaceholderTextColor
		label.text = "Yeni bir mesaj gönder."
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		return label
	}()

	internal lazy var descriptionLabel: UILabel = {
		let label = UILabel()
		label.numberOfLines = 5
		label.textAlignment = .center
		label.font = Desk360.Config.Requests.Listing.Placeholder.Description.font
		label.textColor = Desk360.Config.currentTheme.listingPlaceholderTextColor
		label.text = "Yeni bir destek mesajı yaratmak için devam edin."
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		return label
	}()

	internal lazy var createRequestButton: UIButton = {
		var button = UIButton(type: .system)
		button.backgroundColor = Desk360.Config.currentTheme.requestSendButtonBackgroundColor
//		button.setTitle("Bize Yazın", for: .normal)
		button.setTitleColor(Desk360.Config.currentTheme.requestSendButtonTintColor, for: .normal)
		button.tintColor = Desk360.Config.currentTheme.requestSendButtonTintColor
		button.layer.cornerRadius = Desk360.Config.Requests.Listing.Placeholder.CreateButton.cornerRadius
		button.layer.borderWidth = 1
		button.clipsToBounds = true
		button.layer.masksToBounds = true
		button.titleLabel?.font = Desk360.Config.Requests.Listing.Placeholder.CreateButton.font
		button.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		return button
	}()

	private lazy var stackView: UIStackView = {
		let view = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
		view.axis = .vertical
		view.distribution = .fill
		view.alignment = .fill
		view.spacing = preferredSpacing * 1.5
		return view
	}()

	internal lazy var bottomScrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.showsVerticalScrollIndicator = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.alwaysBounceVertical = true

		return scrollView
	}()

	internal lazy var bottomDescriptionLabel: UILabel = {
		let label = UILabel()
		label.numberOfLines = 0
		label.textAlignment = .center
		label.font = Desk360.Config.Requests.Listing.Placeholder.BottomDescription.font
		label.textColor = Desk360.Config.currentTheme.listingPlaceholderTextColor
		label.text = "Destek mesajlarınız mesai saatleri içerisinde yanıtlar. Buraya buna benzer bir içerik mesajı ve alt kısa açıklama eklenir. Geliştirici istediği mesajı burada verebilir. Kullanılması zorunlu değildir. Destek mesajlarınız mesai saatleri içerisinde yanıtlar. Destek mesajlarınız mesai saatleri içerisinde yanıtlar. Buraya buna benzer bir içerik mesajı ve alt kısa açıklama eklenir. Geliştirici istediği mesajı burada verebilir. Kullanılması zorunlu değildir. Destek mesajlarınız mesai saatleri içerisinde yanıtlar. Destek mesajlarınız mesai saatleri içerisinde yanıtlar. Buraya buna benzer bir içerik mesajı ve alt kısa açıklama eklenir. Geliştirici istediği mesajı burada verebilir. Kullanılması zorunlu değildir. Destek mesajlarınız mesai saatleri içerisinde yanıtlar."
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		return label
	}()

	private lazy var desk360BottomView: UIView = {
		let view = UIView()
		view.backgroundColor =  Desk360.Config.currentTheme.desk360ViewBackgroundColor
		view.addSubview(self.desk360Label)
		view.addSubview(self.poweredByLabel)
		return view
	}()

	private lazy var desk360Label: UILabel = {
		let label = UILabel()
		label.textColor = Desk360.Config.currentTheme.desk360LabelTextColor
		label.text = " DESK360 "
		label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
		label.textAlignment = .right
		return label
	}()

	private lazy var poweredByLabel: UILabel = {
		let label = UILabel()
		label.textColor = Desk360.Config.currentTheme.desk360LabelTextColor
		label.text = "powered by"
		label.font = UIFont.systemFont(ofSize: 12)
		label.textAlignment = .right
		return label
	}()

	public override var backgroundColor: UIColor? {
		didSet {
			titleLabel.backgroundColor = backgroundColor
		}
	}

	func setupViews() {
		backgroundColor = Desk360.Config.currentTheme.backgroundColor
		addSubview(stackView)
		addSubview(createRequestButton)
		addSubview(bottomScrollView)
		addSubview(desk360BottomView)
		bottomScrollView.addSubview(bottomDescriptionLabel)
	}

	func setupLayout() {

		createRequestButton.snp.makeConstraints { make in
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size) - (preferredSpacing * 3))
			make.bottom.equalTo(bottomScrollView.snp.top).offset(-preferredSpacing * 0.5)
			make.height.equalTo(UIButton.preferredHeight * 1.25)
			make.centerX.equalToSuperview()
		}

		stackView.snp.makeConstraints { make in
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size) - (preferredSpacing * 3))
			make.top.greaterThanOrEqualTo(safeArea.top).inset(preferredSpacing)
			make.bottom.lessThanOrEqualTo(createRequestButton.snp.top).inset(preferredSpacing)
			make.centerX.equalToSuperview()
			make.centerY.equalToSuperview().offset(-preferredSpacing * 4)
		}

		bottomScrollView.snp.makeConstraints { make in
			make.bottom.equalTo(desk360BottomView.snp.top)
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size))
			make.centerX.equalToSuperview()
			make.height.equalTo(preferredSpacing * 2.5)
		}

		bottomDescriptionLabel.snp.makeConstraints { make in
			make.centerX.equalToSuperview()
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size) - (preferredSpacing * 3))
			make.top.equalToSuperview()
			make.height.greaterThanOrEqualTo(preferredSpacing * 2.5)
		}

		desk360BottomView.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview()
			make.height.equalTo(preferredSpacing * 1.5)
			make.bottom.equalTo(safeArea.bottom)
		}

		desk360Label.snp.makeConstraints { make in
			make.bottom.top.equalToSuperview()
			make.right.equalToSuperview().inset(preferredSpacing * 0.5)
		}

		poweredByLabel.snp.makeConstraints { make in
			make.bottom.top.equalToSuperview()
			make.right.equalTo(desk360Label.snp.left)
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()

//		createRequestButton.setImageAndTitle()
//		bottomScrollView.contentSize = CGSize(width: Int(UIScreen.main.bounds.width), height: Int(bottomDescriptionLabel.frame.height + preferredSpacing))
//		print("test")
//		print(Int(bottomDescriptionLabel.frame.height + preferredSpacing))
	}

}

// MARK: - Helpers
extension CreatRequestPreView {

	func createButtonType1() {
		createRequestButton.layer.cornerRadius = 22
		setupButtonDefaultLayout()
	}

	func createButtonType2() {
		createRequestButton.layer.cornerRadius = 10
		setupButtonDefaultLayout()
	}

	func createButtonType3() {
		createRequestButton.layer.cornerRadius = 2
		setupButtonDefaultLayout()
	}

	func createButtonType4() {

		createRequestButton.layer.cornerRadius = 0

		var offset = preferredSpacing * 0.5

		if !(Config.shared.model.createPreScreen?.bottomNoteIsHidden ?? false) {
			offset = 0
		}

		createRequestButton.snp.remakeConstraints { make in
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size) + 2)
			if !(Config.shared.model.createPreScreen?.bottomNoteIsHidden ?? false) {
				make.bottom.equalTo(desk360BottomView.snp.top)
			} else {
				make.bottom.equalTo(bottomScrollView.snp.top).offset(-preferredSpacing * 0.5)
			}
			make.height.equalTo(UIButton.preferredHeight * 1.25)
			make.centerX.equalToSuperview()
		}
	}

	func setupButtonDefaultLayout() {
		createRequestButton.snp.remakeConstraints { make in
			make.width.equalTo(minDimension(size: UIScreen.main.bounds.size) - (preferredSpacing * 3))
			make.bottom.equalTo(bottomScrollView.snp.top).offset(-preferredSpacing * 0.5)
			make.height.equalTo(UIButton.preferredHeight * 1.25)
			make.centerX.equalToSuperview()
		}
	}


}

// MARK: - Configure
extension CreatRequestPreView {

	func configure() {
		self.backgroundColor = Colors.backgroundColor
		titleLabel.text = Config.shared.model.createPreScreen?.title
		titleLabel.textColor = Colors.createPreScreenTitleColor
		titleLabel.font = UIFont.systemFont(ofSize: CGFloat(Config.shared.model.createPreScreen?.titleFontSize ?? 18), weight: Font.weight(type: Config.shared.model.createPreScreen?.titleFontWeight ?? 400))

		descriptionLabel.text = Config.shared.model.createPreScreen?.description
		descriptionLabel.textColor = Colors.createPreScreenDescriptionColor
		descriptionLabel.font = UIFont.systemFont(ofSize: CGFloat(Config.shared.model.createPreScreen?.descriptionFontSize ?? 14), weight: Font.weight(type:Config.shared.model.createPreScreen?.descriptionFontWeight ?? 400))

		createRequestButton.backgroundColor = Colors.createPreScreenButtonBackgroundColor
		createRequestButton.layer.borderColor = Colors.createPreScreenButttonBorderColor.cgColor
		createRequestButton.setTitleColor(Colors.createPreScreenButtonTextColor, for: .normal)
		createRequestButton.tintColor = Colors.createPreScreenButtonTextColor
		createRequestButton.titleLabel?.font = UIFont.systemFont(ofSize: CGFloat(Config.shared.model.createPreScreen?.buttonTextFontSize ?? 14), weight: Font.weight(type:Config.shared.model.createPreScreen?.buttonTextFontWeight ?? 400))
		createRequestButton.setTitle(Config.shared.model.createPreScreen?.buttonText, for: .normal)
		bottomDescriptionLabel.text = Config.shared.model.createPreScreen?.bottomNoteText
		bottomDescriptionLabel.textColor = Colors.bottomNoteColor
		bottomDescriptionLabel.font = UIFont.systemFont(ofSize: CGFloat(Config.shared.model.generalSettings?.bottomNoteFontSize ?? 8), weight: Font.weight(type:Config.shared.model.generalSettings?.bottomNoteFontWeight ?? 400))
		bottomDescriptionLabel.sizeToFit()
		bottomScrollView.isHidden = !(Config.shared.model.createPreScreen?.bottomNoteIsHidden ?? false)
		bottomScrollView.isUserInteractionEnabled = Config.shared.model.createPreScreen?.bottomNoteIsHidden ?? false

//		if !(Config.shared.model.createPreScreen?.bottomNoteIsHidden ?? false) {
//			bottomScrollView.snp.remakeConstraints { make in
//				make.bottom.equalTo(desk360BottomView.snp.top)
//				make.width.equalTo(minDimension(size: UIScreen.main.bounds.size))
//				make.centerX.equalToSuperview()
//				make.height.equalTo(0)
//			}
//		}

		configureButton()

	}

	func configureButton() {
		let type = Config.shared.model.createPreScreen?.buttonStyleId

		let imageIshidden =  Config.shared.model.createPreScreen?.buttonIconIsHidden ?? true
		let buttonShadowIsHidden = Config.shared.model.createPreScreen?.buttonShadowIsHidden ?? true

		switch type {
		case 1:
			createButtonType1()
		case 2:
			createButtonType2()
		case 3:
			createButtonType3()
		case 4:
			createButtonType4()
		default:
			createButtonType1()
		}

		if imageIshidden {
			createRequestButton.setImage(Desk360.Config.Requests.Listing.Cell.Unread.icon, for: .normal)
			createRequestButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
			createRequestButton.imageView?.tintColor = Colors.createPreScreenButtonTextColor

//			let imageView = UIImageView()
//			imageView.frame.size.width = createRequestButton.imageView?.frame.size.width ?? 0
//			imageView.frame.size.height = createRequestButton.imageView?.frame.size.height ?? 0
//			imageView.frame.origin.y = createRequestButton.imageView?.frame.origin.y ?? 0
//			imageView.frame.origin.x = (createRequestButton.titleLabel?.frame.origin.x ?? 0) + (createRequestButton.titleLabel?.frame.size.width ?? 0) - ( createRequestButton.imageView?.frame.size.width ?? 0)
//			imageView.image = Desk360.Config.Requests.Listing.Cell.Unread.icon
//			imageView.tintColor = Colors.createPreScreenButtonTextColor
//			createRequestButton.addSubview(imageView)
		}

		if buttonShadowIsHidden {
			createRequestButton.layer.shadowColor = UIColor.black.cgColor
			createRequestButton.layer.shadowOffset = CGSize.zero
			createRequestButton.layer.shadowRadius = 10
			createRequestButton.layer.shadowOpacity = 0.3
			createRequestButton.layer.masksToBounds = false
		}
	}

}

// MARK: - Helpers
extension CreatRequestPreView {

	/// Returns width or height, whichever is the smaller value.
	func minDimension(size: CGSize) -> CGFloat {
		return min(size.width, size.height)
	}

}