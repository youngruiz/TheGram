//
//  FeedViewController.swift
//  TheGram
//
//  Created by Daniel Ruiz on 3/5/22.
//

import UIKit
import Parse
import AlamofireImage
import CryptoKit
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MessageInputBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // Create an instance of MessageinputBar.
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    
    var posts = [PFObject]()
    var selectedPost: PFObject!


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self

        tableView.delegate.self = self
        tableView.dataSource.self = self
        // Do any additional setup after loading the view.
        
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHiddem(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    
    @objc func keyboardWillBeHiddem(note: Notification) {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    
        super.viewDidAppear(animated)
        
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground {(posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
            
            else {
                print("Error getting posts!")
            }
        }
        
        
    }
    
    
    
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment.
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()
        
        selectedPost.add(comment, forKey: "comments")
        
        selectedPost.saveInBackground { (success, error) in

            if success {
                print("Comment saved")
            }
            
            else {
                print("Commment not saved")
            }
        }
        
        tableView.reloadData()
        
        
        // Clear and dismiss the comment.
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    
    
    
    
    // Function for comments.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    

    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! postCell
            //let post = posts[indexPath.row]
            
            let user = post["author"] as! PFUser
            
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as! String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af.setImage(withURL: url)
            
            return cell
        }
        
        else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String

            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username

            return cell
                            
        }
        
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
        
            return cell
        }
    }
    

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post

        }
        
//        comment["text"] = "This is a random comment"
//        comment["post"] = post
//        comment["author"] = PFUser.current()
        
//        post.add(comment, forKey: "comments")
        
//        post.saveInBackground { (success, error) in
//
//            if success {
//                print("Comment saved")
//            }
//            else {
//                print("Commment not saved")
//            }
//        }
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    @IBAction func onLogoutButton(_ sender: Any) {
        
        // Clear the parse cache.
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "loginViewController")
        guard let windoeScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windoeScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
        
    }
    
}
