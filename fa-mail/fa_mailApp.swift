//
//  fa_mailApp.swift
//  fa-mail
//
//  Created by Sebastian Campos on 12/31/24.
//

import SwiftUI


class EmailDetailViewController: UIViewController {
    
    var email: MCOIMAPMessage?
    var fetchContentClosure: ((@escaping (String) -> Void) -> Void)?
    
    private let subjectLabel = UILabel()
    private let fromLabel = UILabel()
    private let dateLabel = UILabel()
    private let bodyTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Email Detail"
        setupViews()
        displayEmailDetails()
    }

    func setupViews() {
        // Set up the views to display email details
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        fromLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.translatesAutoresizingMaskIntoConstraints = false
        
        bodyTextView.isEditable = false
        bodyTextView.font = UIFont.systemFont(ofSize: 14)
        
        view.addSubview(subjectLabel)
        view.addSubview(fromLabel)
        view.addSubview(dateLabel)
        view.addSubview(bodyTextView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            subjectLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            subjectLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            fromLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 10),
            fromLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fromLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: fromLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            bodyTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            bodyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    func displayEmailDetails() {
        guard let email = email else { return }
        
        subjectLabel.text = "Subject: \(email.header.subject ?? "No Subject")"
        fromLabel.text = "From: \(email.header.sender.displayName ?? "Unknown Sender")"
        dateLabel.text = "Date: \(email.header.date?.description ?? "Unknown Date")"
        
        // Fetch the body using the passed closure
        fetchContentClosure? { [weak self] body in
            DispatchQueue.main.async {
                self?.bodyTextView.text = body
            }
        }
    }
}

class EmailViewController: UITableViewController {
    var emails: [MCOIMAPMessage] = []
    var imapSession: MCOIMAPSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        imapSession = MCOIMAPSession()
        imapSession.hostname = "friendlyautomations.com"
        imapSession.username = "sebash"
        imapSession.password = "WendyM1lo7"
        imapSession.port = 993
        imapSession.connectionType = .TLS
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmailCell")
    
        fetchEmails()
    }

    func fetchEmails() {
        let folder = "INBOX"
        let fetchOperation = imapSession.fetchMessagesByNumberOperation(withFolder: folder, requestKind: .headers, numbers: MCOIndexSet(range: MCORange(location: 1, length: 2)))

        fetchOperation?.start { [weak self] error, messages, vanishedMessages in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            guard let messages = messages as? [MCOIMAPMessage] else {
                return
            }
            self?.emails = messages
            self?.tableView.reloadData()
        }
    }
    
    func useImapFetchContent(uidToFetch uid: UInt32, completion: @escaping (String) -> Void) {
        let operation = imapSession.fetchParsedMessageOperation(withFolder: "INBOX", uid: uid)
        
        operation?.start { (error, messageParser) in
            guard error == nil, let messageParser = messageParser else {
                completion("Error fetching body")
                return
            }
            
            // Get the plain text body
            let body = messageParser.plainTextBodyRenderingAndStripWhitespace(false)
            
            // Return the body via the completion handler
            completion(body ?? "No body content")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailCell", for: indexPath)
        let email = emails[indexPath.row]
        cell.textLabel?.text = email.header.subject ?? "No Subject"
        cell.detailTextLabel?.text = email.header.sender.displayName
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let email = emails[indexPath.row]
        
        // Initialize the EmailDetailViewController and pass the selected email and fetch method
        let detailViewController = EmailDetailViewController()
        detailViewController.email = email
        detailViewController.fetchContentClosure = { [weak self] completion in
            self?.useImapFetchContent(uidToFetch: email.uid, completion: completion)
        }
        
        // Push the detail view controller
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

struct EmailViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let emailVC = EmailViewController()
        let navigationController = UINavigationController(rootViewController: emailVC)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Any updates to the view controller can go here.
    }
}




@main
struct fa_mailApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView { // Make sure the NavigationView is here
                EmailViewControllerWrapper()
            }
        }
    }
}
