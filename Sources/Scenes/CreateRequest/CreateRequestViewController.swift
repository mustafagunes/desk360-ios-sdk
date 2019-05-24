//
//  CreateRequestViewController.swift
//  Desk360
//
//  Created by samet on 18.05.2019.
//

import UIKit

final class CreateRequestViewController: UIViewController, Layouting {

	typealias ViewType = CreateRequestView
	override func loadView() {
		view = ViewType.create()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		layoutableView.sendButton.addTarget(self, action: #selector(didTapSendRequestButton), for: .touchUpInside)
		registerForKeyboardEvents()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		navigationItem.title = Desk360.Strings.Support.createTitle

		fetchTicketType()

		if let icon = Desk360.Config.Requests.Create.backBarButtonIcon {
			navigationController?.navigationBar.backIndicatorImage = icon
			navigationController?.navigationBar.backIndicatorTransitionMaskImage = icon
			navigationItem.backBarButtonItem = .init(title: "", style: .plain, target: nil, action: nil)
		}
	}

	@objc private func didTapSendRequestButton() {

		guard let name = layoutableView.nameTextField.trimmedText, name.count > 2 else {
			layoutableView.nameTextField.shake()
			layoutableView.nameTextField.becomeFirstResponder()
			return
		}

		guard let email = layoutableView.emailTextField.emailAddress else {
			layoutableView.emailTextField.shake()
			layoutableView.emailTextField.becomeFirstResponder()
			return
		}

		guard let subject = layoutableView.subjectTextField.trimmedText, subject.count > 2 else {
			layoutableView.subjectTextField.shake()
			layoutableView.subjectTextField.becomeFirstResponder()
			return
		}

		guard layoutableView.dropDownListView.getSelectedIndex != -1 else {
			layoutableView.dropDownListView.shake()
			layoutableView.dropDownListView.showList()
			return
		}

		guard let message = layoutableView.messageTextView.trimmedText, message.count > 3 else {
			layoutableView.messageTextView.shake()
			layoutableView.messageTextView.becomeFirstResponder()
			return
		}

		let ticketTypes = layoutableView.ticketTypes
		guard ticketTypes.count > 0 else { return }
		let ticketTypeId = ticketTypes[layoutableView.dropDownListView.getSelectedIndex].id
		sendRequest(name: name, email: email, subject: subject, ticketType: String(ticketTypeId), message: message)
	}

}

// MARK: - KeyboardObserving
extension CreateRequestViewController: KeyboardObserving {

	func keyboardWillShow(_ notification: KeyboardNotification?) {
		layoutableView.keyboardWillShow(notification)
	}

	func keyboardDidHide(_ notification: KeyboardNotification?) {
		layoutableView.keyboardDidHide(notification)
	}

	func keyboardDidShow(_ notification: KeyboardNotification?) {}
	func keyboardWillHide(_ notification: KeyboardNotification?) {}
	func keyboardWillChangeFrame(_ notification: KeyboardNotification?) {}
	func keyboardDidChangeFrame(_ notification: KeyboardNotification?) {}

}

// MARK: - Networking
private extension CreateRequestViewController {

	func fetchTicketType() {
		Desk360.apiProvider.request(.ticketTypeList) { [weak self] result in
			guard let self = self else { return }
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .success(let response):
				guard let ticketTypes = try? response.map(DataResponse<[TicketType]>.self) else { return }
				guard let ticketsTypes = ticketTypes.data else { return }
				self.layoutableView.ticketTypes.removeAll()
				self.layoutableView.ticketTypes = ticketsTypes
				self.layoutableView.setTicketType(ticketTypes: ticketsTypes)
			}
		}
	}

	func sendRequest(name: String, email: String, subject: String, ticketType: String, message: String) {
		let request = TicketRequest(name: name, email: email, subject: subject, message: message, type_id: ticketType, source: "App", platform: "iOS", country_code: Locale.current.countryCode)

		layoutableView.endEditing(true)
		layoutableView.setLoading(true)
		Desk360.apiProvider.request(.create(request)) { [weak self] result in
			guard let self = self else { return }
			self.layoutableView.setLoading(false)
			switch result {
			case .failure(let error):
				print(error.localizedServerDescription)
			case .success:
				self.navigationController?.popViewController(animated: true)
			}
		}
	}

}