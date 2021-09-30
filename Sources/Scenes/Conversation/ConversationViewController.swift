//
//  ConversationViewController.swift
//  Desk360
//
//  Created by samet on 18.05.2019.
//

import UIKit
import Photos
import Moya

final class ConversationViewController: UIViewController, Layouting, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIDocumentBrowserViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {

	var request: Ticket!
	var message: String = ""
    var files = [fileData]()
	convenience init(request: Ticket) {
		self.init()
		self.request = request
	}

	typealias ViewType = ConversationView

	var isAddedMessage = false

	override func loadView() {
		view = ViewType.create()
	}

	override var inputAccessoryView: UIView? {
		let view = layoutableView.conversationInputView
		view.delegate = self
		view.configure(for: request)
		return view
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

    var safeAreaBottom: CGFloat = {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        } else {
            return 0
        }
    }()

	/// This parameter is used to ticket media objects
	var attachment: URL?
    var isConfigure = false
	/// This parameter is used to fix to problems created by the custom keyboard
	var previousLineCount = 0
	var currentLineCount = 0
    var refreshIcon = UIImageView()
    var aiv = UIActivityIndicatorView()
    var isDragReleased = false

	var safeAreaTop: CGFloat = {
		if #available(iOS 11.0, *) {
			return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
		} else {
			return 0
		}
	}()

	func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
		scrollToBottom(animated: false)
		return false
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		registerForKeyboardEvents()
		layoutableView.conversationInputView.delegate = self
		layoutableView.conversationInputView.createRequestButton.addTarget(self, action: #selector(didTapNewRequestButton), for: .touchUpInside)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        Desk360.conVC = self
		setMessages()
		previousLineCount = 0
		currentLineCount = 0
		layoutableView.tableView.dataSource = self
		layoutableView.tableView.delegate = self

		layoutableView.conversationInputView.layoutIfNeeded()
		layoutableView.conversationInputView.layoutSubviews()

		navigationController?.interactivePopGestureRecognizer?.isEnabled = true
		navigationController?.interactivePopGestureRecognizer?.delegate  = self
		navigationItem.leftBarButtonItem = NavigationItems.back(target: self, action: #selector(didTapBackButton))

		configure()

		layoutableView.remakeTableViewConstraint(bottomInset: layoutableView.conversationInputView.frame.size.height)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		layoutableView.setLoading(self.request.messages.isEmpty)
		readRequest(request)
//        layoutableView.conversationInputView.resetAttachView()
	}

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    func refreshAction() {
        readRequest(request)
    }

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        Desk360.conVC = nil
		layoutableView.conversationInputView.textView.resignFirstResponder()
		layoutableView.conversationInputView.layoutIfNeeded()
		layoutableView.conversationInputView.layoutSubviews()
		setRead()

	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if isAddedMessage && indexPath.row == request.messages.count - 1 {
			cell.isSelected = false
		} else {
			cell.isSelected = true
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return request.messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = request.messages[indexPath.row]

        var hasAttach = false
        if message.attachments?.images?.count ?? 0 > 0 ||
        message.attachments?.videos?.count ?? 0 > 0 ||
        message.attachments?.files?.count ?? 0 > 0 ||
        message.attachments?.others?.count ?? 0 > 0 {
            hasAttach = true
        }

		if message.isAnswer {
			let cell = tableView.dequeueReusableCell(SenderMessageTableViewCell.self)
            cell.clearCell()
            cell.configure(for: request.messages[indexPath.row], hasAttach: hasAttach)
			return cell
		}
		let cell = tableView.dequeueReusableCell(ReceiverMessageTableViewCell.self)
        cell.clearCell()
        cell.configure(for: request.messages[indexPath.row], indexPath, attachment, hasAttach: hasAttach)
		return cell
	}

}

// MARK: - ConversationInputViewDelegate
extension ConversationViewController: InputViewDelegate {

	func inputView(_ view: InputView, didTapCreateRequestButton button: UIButton) {
	}

	func inputView(_ view: InputView, didTapSendButton button: UIButton, withText text: String) {
		layoutableView.conversationInputView.setLoading(true)
		isAddedMessage = true
		addMessage(text, to: request)
	}

    func inputView(_ view: InputView, didTapAttachButton button: UIButton) {
        guard files.count <= 4 else { return }
        view.attachButton.isHidden = true
        view.sendButton.isHidden = true
        view.isHidden = true
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .fullScreen
        let showImagePicker = UIAlertAction(title: Config.shared.model?.generalSettings?.attachmentImagesText ?? "Images", style: .default) { _ in
            self.didTapImagePicker {
                view.attachButton.isHidden = false
                view.sendButton.isHidden = false
                view.isHidden = false
            }
        }
        let showFilePicker = UIAlertAction(title: Config.shared.model?.generalSettings?.attachmentBrowseText ?? "Browse", style: .default) { _ in
            self.didTapDocumentBrowse {
                view.attachButton.isHidden = false
                view.sendButton.isHidden = false
                view.isHidden = false
            }
        }
        let cancelAction = UIAlertAction(title: Config.shared.model?.generalSettings?.attachmentCancelText ?? "Cancel", style: .cancel) { _ in
            view.attachButton.isHidden = false
            view.sendButton.isHidden = false
            view.isHidden = false
        }

        if #available(iOS 11.0, *) {
            alert.addAction(showFilePicker)
        }
        alert.addAction(showImagePicker)
        alert.addAction(cancelAction)
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = layoutableView.conversationInputView.attachButton
            popoverPresentationController.sourceRect = layoutableView.conversationInputView.attachButton.bounds
        }
        present(alert, animated: true)
    }

    @objc func didTapDocumentBrowse(completion: @escaping (() -> Void)) {

        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true) {
            self.isConfigure = true
            completion()
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

        guard let url = urls.first else { return }
        guard let pdfData = try? Data(contentsOf: url) else { return }
        guard let name = url.pathComponents.last else { return }
        guard pdfData.count < 5242880 else {
            controller.dismiss(animated: true) {
                Alert.showAlert(viewController: self, title: "Desk360", message: Config.shared.model?.generalSettings?.fileSizeErrorText ?? "")
            }
            return
        }
        files.append(fileData(name: name, data: pdfData, url: url.absoluteString, type: "pdf"))
        controller.dismiss(animated: true) {
            self.manageAttachView()
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true) {
            self.manageAttachView()
        }
    }

    @objc func didTapImagePicker(completion: @escaping (() -> Void)) {
        let imagePicker: UIImagePickerController = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true) {
            self.isConfigure = true
            completion()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.manageAttachView()
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard var imgUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL else { return }
        guard var name = imgUrl.pathComponents.last else { return }
        guard files.count <= 4 else { return }
        if #available(iOS 11.0, *) {
            imgUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL ?? imgUrl
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                let assetResources = PHAssetResource.assetResources(for: asset)
                name = assetResources.first?.originalFilename ?? ""
                print(name)
            }
        }

        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let data = image.jpegData(compressionQuality: 0.3) as NSData? else { return }
            guard data.length < 5242880 else {
                picker.dismiss(animated: true) {
                    Alert.showAlert(viewController: self, title: "Desk360", message: Config.shared.model?.generalSettings?.fileSizeErrorText ?? "")
                }
                return
            }
            files.append(fileData(name: name, data: Data(referencing: data), url: imgUrl.absoluteString, type: "image/jpeg"))
        } else {
            if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                guard let data = try? NSData(contentsOf: videoUrl as URL, options: .mappedIfSafe) else { return }
                guard data.length < 5242880 else {
                    picker.dismiss(animated: true) {
                        Alert.showAlert(viewController: self, title: "Desk360", message: Config.shared.model?.generalSettings?.fileSizeErrorText ?? "")
                    }
                    return
                }
                files.append(fileData(name: name, data: Data(referencing: data), url: videoUrl.absoluteString, type: "video"))
            }
        }

        let abc = files.map({($0.data as NSData).length})
        let dataSize = abc.reduce(0, +)
        guard dataSize < 5242880 else {
            picker.dismiss(animated: true) {
                Alert.showAlert(viewController: self, title: "Desk360", message: Config.shared.model?.generalSettings?.fileSizeErrorText ?? "")
            }
            return
        }

        picker.dismiss(animated: true) {
            self.manageAttachView()
        }
    }

    func manageAttachView() {
        guard files.count <= 5 else { return }
        for v in self.layoutableView.conversationInputView.stackView.subviews {
            v.removeFromSuperview()
        }
        layoutableView.conversationInputView.resetAttachView()
        layoutableView.conversationInputView.isHidden = false
        layoutableView.conversationInputView.attachButton.isHidden = false
        layoutableView.conversationInputView.sendButton.isHidden = false
        if files.count <= 0 {
            return
        }
        var height: CGFloat = 22
        var maxWidth: CGFloat = 0
        var hStack = getAStackView()
        hStack.frame = CGRect(x: 0, y: 0, width: self.layoutableView.conversationInputView.stackView.frame.size.width, height: 20)
        var i = 0
        var yPoint: CGFloat = 0
        for file in files {
            let lbl = UILabel()
            lbl.numberOfLines = 0
            lbl.text = file.name
            lbl.textColor = Colors.receiverFileNameColor
            lbl.font = .systemFont(ofSize: 12)
            lbl.sizeToFit()
            lbl.adjustsFontSizeToFitWidth = true
            lbl.minimumScaleFactor = 0.3
            lbl.frame = CGRect(x: 4, y: 0, width: lbl.frame.width, height: 20)

            let view = UIView(frame: CGRect(x: maxWidth, y: 0, width: lbl.frame.width + 30, height: 20))
            view.backgroundColor = Colors.attachBgColor
            view.addSubview(lbl)
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            maxWidth = maxWidth + lbl.frame.width + 32

            if i == 0 {
                self.layoutableView.conversationInputView.stackView.addSubview(hStack)
            }
            if maxWidth > self.layoutableView.conversationInputView.stackView.frame.size.width {
                yPoint = yPoint + 22
                height = height + 22
                view.frame = CGRect(x: 0, y: 0, width: lbl.frame.width + 30, height: 20)
                hStack = getAStackView()
                hStack.frame = CGRect(x: 0, y: yPoint, width: self.layoutableView.conversationInputView.stackView.frame.size.width, height: 20)
                self.layoutableView.conversationInputView.stackView.addSubview(hStack)
                maxWidth = lbl.frame.width + 32
            }

            let btn = UIButton(frame: CGRect(x: lbl.frame.size.width + 4, y: 0, width: 24, height: 20))
            btn.addTarget(self, action: #selector(removeAttach(_:)), for: .touchUpInside)
            btn.accessibilityIdentifier = file.url
            btn.setImage(Desk360.Config.Images.attachRemoveIcon, for: .normal)
            btn.backgroundColor = .clear
            view.addSubview(btn)
            hStack.addSubview(view)

            i = i + 1
        }

        self.layoutableView.conversationInputView.setFrame(height: height)
        let text = self.layoutableView.conversationInputView.textView.text
        if text != "" {
            DispatchQueue.main.async {
                self.layoutableView.conversationInputView.textView.text = "\(text)."
                self.layoutableView.conversationInputView.textViewDidChange(self.layoutableView.conversationInputView.textView)
                self.layoutableView.conversationInputView.textView.text = text
                self.layoutableView.conversationInputView.textViewDidChange(self.layoutableView.conversationInputView.textView)
            }
        }
    }

    func getAStackView() -> UIView {
        let hStack = UIView()
        return hStack
    }

    @objc func removeAttach(_ sender: UIButton) {
        var i = 0
        for file in files {
            if file.url == sender.accessibilityIdentifier {
                files.remove(at: i)
                manageAttachView()
                break
            }
            i = i + 1
        }
        let text = self.layoutableView.conversationInputView.textView.text
        if text != "" {
            DispatchQueue.main.async {
                self.layoutableView.conversationInputView.textView.text = "\(text)."
                self.layoutableView.conversationInputView.textViewDidChange(self.layoutableView.conversationInputView.textView)
                self.layoutableView.conversationInputView.textView.text = text
                self.layoutableView.conversationInputView.textViewDidChange(self.layoutableView.conversationInputView.textView)
            }
        }
    }
}

// MARK: - Networking
extension ConversationViewController {

	/// This method use is to get one ticket from the use id
	/// - Parameter request: this parameter is a ticket object we will use its id and we will use its properties
    func readRequest(_ request: Ticket) {

		guard Desk360.isReachable else {
			networkError()
			return
		}
        showPDR()
		Desk360.apiProvider.request(.ticketWithId(request.id)) { [weak self] result in
			guard let self = self else { return }
            self.hidePDR()
			self.layoutableView.setLoading(false)
			switch result {
			case .failure(let error):
				if error.response?.statusCode == 400 {
					Desk360.isRegister = false
					Alert.showAlertWithDismiss(viewController: self, title: "Desk360", message: "general.error.message".localize(), dissmis: true)
					return
				}

			case .success(let response):
                guard let tickets = try? response.map(DataResponse<Ticket>.self) else { return }
                guard let data = tickets.data else { return }
                self.request = data
                let storedTickets = Stores.ticketWithMessageStore.allObjects() // fetch previously saved tickets from the local just before save new tickets
                try? Stores.ticketWithMessageStore.save(self.request)// save new tickets to the local.
                if let url = data.attachmentUrl {
                    self.attachment = url // attachments will be allways at first row of tableview.
                }
                if let msg = self.request.messages.last {
                    let currentTicketWithMessage = storedTickets.filter({ $0.id == self.request.id })
                    if currentTicketWithMessage.count > 0 {
                        if let mesaj = currentTicketWithMessage[0].messages.last {
                            if msg.id == mesaj.id {
                                if let url = data.attachmentUrl {
                                    if self.request != nil {
                                        DispatchQueue.main.async {
                                            // attachments will be allways at first row of tableview.
                                            let indexPath = IndexPath(row: 0, section: 0)
                                            guard self.layoutableView.tableView.isValid(indexPath: indexPath) else { return }
                                            self.layoutableView.tableView.reloadRows(at: [indexPath], with: .none)
                                        }
                                    }
                                }
                                self.scrollToBottom(animated: false)
                                return // don't reload table to avoid performance issues
                            }
                        }
                    }
                }

                self.layoutableView.tableView.reloadData()
                self.scrollToBottom(animated: false)
			}
		}
	}

	/// This method is used to send a request to backend for add a message in ticket
	/// - Parameters:
	///   - message: this parameter is a user message
	///   - request: this parameter is a ticket object
	func addMessage(_ message: String, to request: Ticket) {

		self.message = message

		guard Desk360.isReachable else {
			networkError()
			return
		}

		let id = (request.messages.last?.id ?? 0) + 1

		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

		layoutableView.conversationInputView.resignFirstResponder()
		self.layoutableView.conversationInputView.reset()
        let attachFiles = self.files
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.appendMessage(message: Message(id: id, message: message, isAnswer: false, createdAt: formatter.string(from: Date())))
            self.files.removeAll()
            self.manageAttachView()
		}
        var attach = [MultipartFormData]()
        if attachFiles.count > 0 {
            attach = attachFiles.map({ Moya.MultipartFormData(provider: .data($0.data), name: "attachments[]", fileName: $0.name.lowercased(), mimeType: $0.type ) })
            layoutableView.conversationInputView.setLoading(true)
        }
        let fieldData = MultipartFormData(provider: .data(message.data(using: .utf8)!), name: "message")
        attach.insert(fieldData, at: 0)
        Desk360.apiProvider.request(.ticketMessages(request.id, attach: attach)) { [weak self] result in
			guard let self = self else { return }
			self.layoutableView.conversationInputView.setLoading(false)
			switch result {
			case .failure(let error):
				if error.response?.statusCode == 400 {
					Desk360.isRegister = false
					Alert.showAlertWithDismiss(viewController: self, title: "Desk360", message: "general.error.message".localize(), dissmis: true)
					return
				}
			case .success(let data):
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.isAddedMessage = false
					self.showActiveCheckMark()
				}
			}
		}
	}
}

// MARK: - Helpers
private extension ConversationViewController {

    enum FileType: String {
        case image = "image"
        case video = "video"
        case file = "file"
        case unknown = "unknown"
    }

    func getFileType(url: URL) -> FileType {
        guard let path = url.pathComponents.last else { return .unknown }
        let words = path.split(separator: ".")
        guard var word = words.last?.lowercased() else { return .unknown }
        if word == "pdf" {
            return .file
        } else if word == "png" || word == "jpeg" || word == "jpg" || word == "svg" || word == "bmp" || word == "heic" {
            return .image
        } else if word == "avi" || word == "mkv" || word == "mov" || word == "wmv" || word == "mp4" || word == "3gp" || word == "qt" {
            return .video
        } else {
            return .unknown
        }
    }
	/// This method is used to  a add a message in ticket
	/// - Parameter message: this parameter is a user message
	func appendMessage(message: Message) {
        var attach = Attachment()
        for file in files {
            let type = getFileType(url: URL(string: file.url)!)
            if type == .image {
                if attach.images == nil {
                    attach.images = [AttachObject]()
                }
                attach.images?.append(AttachObject(url: file.url, name: file.name, type: type.rawValue))
            }
            if type == .video {
                if attach.videos == nil {
                    attach.videos = [AttachObject]()
                }
                attach.videos?.append(AttachObject(url: file.url, name: file.name, type: type.rawValue))
            }
            if type == .file {
                if attach.files == nil {
                    attach.files = [AttachObject]()
                }
                attach.files?.append(AttachObject(url: file.url, name: file.name, type: type.rawValue))
            }
        }
        var msgObject = message
        msgObject.attachments = attach

		self.request.messages.append(msgObject)
		try? Stores.ticketWithMessageStore.save(self.request)

		self.layoutableView.tableView.beginUpdates()
		let indexPath = IndexPath(row: self.request.messages.count - 1, section: 0)
		self.layoutableView.tableView.insertRows(at: [indexPath], with: .top)
		self.layoutableView.tableView.endUpdates()

		try? Stores.ticketsStore.save(self.request)

	}

	/// This method is used to scroll to tableview bottom
	/// - Parameter animated:this parameter is used  to scroll animation
	func scrollToBottom(animated: Bool) {
		let row = request.messages.count - 1
		guard row >= 0 else { return }
        if Desk360.conVC == nil { return }
		let lastIndexPath = IndexPath(row: row, section: 0)
        guard layoutableView.tableView.isValid(indexPath: lastIndexPath) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			self.layoutableView.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
		})
	}

	func showActiveCheckMark() {
		let indexPath = IndexPath(row: request.messages.count - 1, section: 0)
		guard let cell = layoutableView.tableView.cellForRow(at: indexPath) else { return }
        guard layoutableView.tableView.isValid(indexPath: indexPath) else { return }
		layoutableView.tableView.reloadRows(at: [indexPath], with: .none)
	}

	func networkError() {
		layoutableView.setLoading(false)

		let cancel = "cancel.button".localize()
		let tryAgain = "try.again.button".localize()

		Alert.shared.showAlert(viewController: self, withType: .info, title: "Desk360", message: "connection.error.message".localize(), buttons: [cancel, tryAgain], dismissAfter: 0.1) { [weak self] value in
			guard let self = self else { return }
			if value == 2 {
				self.addMessage(self.message, to: self.request)
			}
		}
	}

}

extension UITableView {

    func isValid(indexPath: IndexPath) -> Bool {
        guard indexPath.section < numberOfSections,
              indexPath.row < numberOfRows(inSection: indexPath.section)
            else { return false }
        return true
    }

}

// MARK: - Actions
extension ConversationViewController {

	func setMessages() {
		let tickets = Stores.ticketWithMessageStore.allObjects()
		let currentTicketWithMessage = tickets.filter({ $0.id == self.request.id })
		guard currentTicketWithMessage.count > 0 else { return }
		self.request.messages = currentTicketWithMessage.first?.messages ?? []
		layoutableView.tableView.reloadData()
		scrollToBottom(animated: false)
	}

	func setRead() {
		let id = request.id
		let tickets = Stores.ticketsStore.allObjects().sorted()

		for ticket in tickets {
			var currentTicket = ticket
			if ticket.id == id {
				if ticket.status == .unread {
					currentTicket.status = .read
				}
				currentTicket.messages = self.request.messages
				if message != "" {
					currentTicket.message = message
				}
				try? Stores.ticketsStore.save(currentTicket)
			}
		}
	}
}

// MARK: - Actions
extension ConversationViewController {

	/// This method is used to direction to create request screen
	@objc func didTapNewRequestButton() {
		navigationController?.pushViewController(CreateRequestViewController(checkLastClass: true), animated: true)
	}

	/// This method is used to pop action on navigationcontroller
	@objc func didTapBackButton() {
		layoutableView.conversationInputView.textView.resignFirstResponder()
		layoutableView.conversationInputView.layoutIfNeeded()
		layoutableView.conversationInputView.layoutSubviews()
		navigationController?.popViewController(animated: true)
	}

}

// MARK: - Configure
extension ConversationViewController {

	func configure() {
		let fontWeight = Font.weight(type: Config.shared.model?.generalSettings?.navigationTitleFontWeight ?? 400)
		let fontSize = CGFloat(Config.shared.model?.generalSettings?.navigationTitleFontSize ?? 16)
		let font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
		let selectedattributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
		NSAttributedString.Key.font: font, NSAttributedString.Key.shadow: NSShadow() ]
		let navigationTitle = NSAttributedString(string: Config.shared.model?.ticketDetail?.title ?? "", attributes: selectedattributes as [NSAttributedString.Key: Any])
		let titleLabel = UILabel()
		titleLabel.attributedText = navigationTitle
		titleLabel.sizeToFit()
		titleLabel.textAlignment = .center
		titleLabel.textColor = Colors.navigationTextColor
		navigationItem.titleView = titleLabel

		navigationItem.title = Config.shared.model?.ticketDetail?.title
		self.navigationController?.navigationBar.setColors(background: Colors.navigationBackgroundColor, text: Colors.navigationTextColor)
		navigationController?.navigationBar.tintColor = Colors.navigationImageViewTintColor
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
		self.navigationController?.navigationBar.shadowImage = UIImage()
		layoutableView.configure()
        aiv.removeFromSuperview()
        aiv = UIActivityIndicatorView(style: .gray)
        aiv.color = Colors.pdrColor
        aiv.frame.size.height = 20
        refreshIcon = UIImageView(image: Desk360.Config.Images.arrowDownIcon)
        let view = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width / 2)-17, y: 0, width: 34, height: 20))
        view.backgroundColor = layoutableView.tableView.backgroundColor
        refreshIcon.frame = CGRect(x: (view.frame.size.width / 2)-7, y: 0, width: 14, height: 19)
        refreshIcon.backgroundColor = layoutableView.tableView.backgroundColor
        refreshIcon.isHidden = true
        aiv.hidesWhenStopped = false
        view.addSubview(refreshIcon)
        aiv.addSubview(view)
        layoutableView.tableView.tableHeaderView = aiv
        layoutableView.conversationInputView.attachButton.isHidden = false
        layoutableView.conversationInputView.sendButton.isHidden = false
	}

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if aiv.isAnimating == false {
            hidePDR()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if aiv.isAnimating == false {
            hidePDR()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragReleased = false
        refreshIcon.isHidden = false
        if aiv.isAnimating {
            return
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        isDragReleased = true
        if aiv.isAnimating == false {
            hidePDR()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if aiv.isAnimating {
            return
        }
        if scrollView.contentOffset.y >= 0 {
            hidePDR()
            return
        }

        if scrollView.contentOffset.y < -23 { // arrow starting to show down direction
            if isDragReleased {
                return
            }

            refreshIcon.isHidden = false
            self.refreshIcon.superview!.isHidden = false
            aiv.hidesWhenStopped = false
            self.aiv.stopAnimating()
        }
        if scrollView.contentOffset.y < -65 { // arrow will turn up
            var val = 0.0

            UIView.animate(withDuration: 0.1, animations: {
                self.aiv.startAnimating()
                self.refreshIcon.transform = CGAffineTransform(rotationAngle: .pi)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.refreshIcon.isHidden = true
                    self.refreshIcon.superview!.isHidden = true
                    self.aiv.hidesWhenStopped = false
                    self.refreshAction()
                }
            })
            return
        }
    }

    func hidePDR() {
        refreshIcon.isHidden = true
        self.refreshIcon.superview!.isHidden = true
        aiv.hidesWhenStopped = true
        self.aiv.stopAnimating()
        self.refreshIcon.transform = CGAffineTransform(rotationAngle: 0)
    }

    func showPDR() {
        refreshIcon.isHidden = true
        self.refreshIcon.superview!.isHidden = true
        aiv.hidesWhenStopped = false
        self.aiv.startAnimating()
    }
}

// MARK: - KeyboardObserving
extension ConversationViewController: KeyboardObserving {

	func keyboardWillShow(_ notification: KeyboardNotification?) { }

	func keyboardWillHide(_ notification: KeyboardNotification?) {

		layoutableView.remakeTableViewConstraint(bottomInset: layoutableView.conversationInputView.frame.size.height)
        if Desk360.conVC != nil {
            scrollToBottom(animated: false)
        }

		layoutableView.conversationInputView.layoutIfNeeded()
		layoutableView.conversationInputView.layoutSubviews()
	}

	func keyboardDidHide(_ notification: KeyboardNotification?) {}
	func keyboardDidShow(_ notification: KeyboardNotification?) {}
	func keyboardWillChangeFrame(_ notification: KeyboardNotification?) {

		guard let keyboardEndFrame = notification?.endFrame else { return }

		currentLineCount = Int(layoutableView.conversationInputView.textView.frame.height / (layoutableView.conversationInputView.textView.font?.lineHeight ?? 1))

		var safeArea: CGFloat = 0

		if layoutableView.isCustomKeyboardActive {
			safeArea = safeAreaBottom
		}

		layoutableView.remakeTableViewConstraint(bottomInset: keyboardEndFrame.size.height - safeArea)
        if Desk360.conVC != nil {
            scrollToBottom(animated: false)
        }
	}
	func keyboardDidChangeFrame(_ notification: KeyboardNotification?) {}

}

struct fileData {
    var name: String
    var data: Data
    var url: String
    var type: String
}
