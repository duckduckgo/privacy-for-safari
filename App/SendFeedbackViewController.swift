//
//  SendFeedbackViewController.swift
//  DuckDuckGo Privacy Essentials
//
//  Copyright © 2019 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit
import Feedback

class SendFeedbackViewController: NSViewController {
        
    @IBOutlet weak var mainScreen: NSView!
    @IBOutlet weak var thanksScreen: NSView!
    @IBOutlet weak var sendFeedbackButton: NSButton!
    @IBOutlet var feedbackForm: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        thanksScreen.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.defaultButtonCell = sendFeedbackButton.cell as? NSButtonCell
        
        if mainScreen.isHidden {
            sendFeedbackButton.isEnabled = false
            feedbackForm.string = ""
            mainScreen.isHidden = false
            thanksScreen.isHidden = true
        }

    }
    
    @IBAction func sendFeedbackPressed(_ sender: Any) {
        mainScreen.isHidden = true
        thanksScreen.isHidden = false
        FeedbackSender().send(feedback: feedbackForm.string)
    }
    
}

extension SendFeedbackViewController: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        sendFeedbackButton.isEnabled = feedbackForm.string.trimmingCharacters(in: .whitespaces).count >= 10
    }
    
}
