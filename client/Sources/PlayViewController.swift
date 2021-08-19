//
//  PlayViewController.swift
//  client
//
//  Created by TanakaHirokazu on 2021/08/18.
//

import UIKit

enum inputButton: Int {
    case input0 = 0
    case input1 = 1
    case input2 = 2
    case input3 = 3
}

class PlayViewController: UIViewController, PlayingDelegate {
    //他の人が回答中
    func answering(userName: String) {
        answeringUser = userName
        print("\(answeringUser)が回答中")
        answerButton.isEnabled = false
        answerButton.backgroundColor = .gray
        stackButtons.isHidden = true
        //TODO: テキスト読み上げ一時停止
        
    }
    
    func startAnswer() {
        print("自分が回答を始めた ")
        stackButtons.isHidden = false
//        stackButtons.backgroundColor = .blue
        (0..<4).forEach {index in ansButtonArray[index].backgroundColor = .blue}
        answerButton.isEnabled = false
        answerButton.backgroundColor = .gray
    }
    
    
    func problemClosed() {
        print("次の問題のリクエスト")
        QuizClient.fetchNextQuiz(roomId: roomId) { quiz in
            self.quiz = quiz
            print(quiz)
        }
        
        nextQuiz()
        
    }
    
    
    func nextQuiz() {
        answerButton.isEnabled = true
        answerButton.backgroundColor = .blue
        stackButtons.isHidden = true
        
        count += 1
        if count < 5 {
            yomiageTimer.invalidate()
            displaySentence()
        } else {
            gameover()
        }
    }
    
    func gameover() {
        self.performSegue(withIdentifier: "toResult", sender: self)
    }
    

    
    @IBOutlet weak var answerField: UILabel!
    
    @IBOutlet weak var stackButtons: UIStackView!
    @IBOutlet weak var answerButton: UIButton!
    
    @IBOutlet var ansButtonArray: [UIButton]!
    
    //選んだ文字
    var choicedAnswer: String = ""
    var count = 0

    var currentCharIndex:Int = 0
    var ansLen:Int = 0
    var answerChoices: [String] = ["", "", "", ""]
    
    //読み上げの文字列
    var yomiageTimer = Timer()
    var currentCharNum = 0
    
    var quiz: Quiz!
    var roomId: String!
    var timerPrg:Timer = Timer()
    let userId = UIDevice.current.identifierForVendor!.uuidString
    var answeringUser: String = ""
    @IBOutlet weak var prg: UIProgressView!
    
    @IBOutlet weak var questionSentence: UITextView!
    var webSocketManager = WebSocketManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webSocketManager.playingdelegate = self
        prg.progress = 1.0
        displaySentence()
        displayChoicesRandomly()
        setUpQuiz()
        updateAnswerField()
    }
    
    @IBAction func tapanswerButton(_ sender: Any) {
        print("回答")
        print(quiz.answerInKana)
        webSocketManager.startAnswer(userId: userId, roomId: roomId)
        
    }
    
    
    
    @IBAction func quitButton(_ sender: Any) {
        dismiss(animated: true) { [self] in
            self.webSocketManager.disconnect()
            self.webSocketManager.connect()
        }
    }
    
    
    
    @IBAction func testSubmitAnswer(_ sender: Any) {
        if roomId == "" { fatalError() }
        webSocketManager.submitAnswer(userId: userId, roomId: roomId, isCorrect: true)
    }
    
    
    @IBAction func inputButtonAction(_ sender: Any) {
        if let button = sender as? UIButton {
            if let tag = inputButton(rawValue: button.tag) {
                
                switch tag {
                case .input0:
                    print("input0")
                    choicedAnswer += answerChoices[0]
                    updateAnswerField()
                    displayChoicesRandomly()
                    
                case .input1:
                    print("input1")
                    choicedAnswer += answerChoices[1]
                    updateAnswerField()
                    displayChoicesRandomly()
                case .input2:
                    print("input2")
                    choicedAnswer += answerChoices[2]
                    updateAnswerField()
                    displayChoicesRandomly()
                case .input3:
                    print("input3")
                    choicedAnswer += answerChoices[3]
                    updateAnswerField()
                    displayChoicesRandomly()
                }
            }
        }
    }
    
    //画面遷移時or問題が切り替わった時に実行
    func setUpQuiz() {
        if let answer = quiz.answerInKana {
            ansLen = answer.count
        } else {
            print("クイズなし")
        }
    }
    
}

//入力ボタン
/*
 ## TIPS
 * hide -> answer -> 各選択肢　（ボタンの押し方）
 ## TODO
 * 記号には対応してない
 * 画面遷移時のイベントはhideボタンで対応
 * 答えるボタンを押すとisHidden=falseをあとに実行しているはずなのに一瞬setTitleされていないボタンが表示されてしまう
 ## PARAM
 * answer: 答え
 * ancChar: 正解の文字
 * currentCharIndex: その時までに表示した文字数
 * ansLen: 答えの文字列の長さ
 * answerChoices: 答えの選択肢
 * ansButtonArray: 選択肢のボタンが入った配列
 ## FUNC
 * strAccess: strのindex番目の文字を返す
 * generateChoicesRandomly: 選択肢をランダムに生成
 * displayChoicesRandomly: 選択肢をランダムに表示
 * hideButton: ボタンを隠す（画面遷移時に実行）
 */
extension PlayViewController {
    
    func updateAnswerField() {
        answerField.text = choicedAnswer
        answerChoices = ["", "", "", ""]
    }
    
    // 文字列で返す。
    func strAccess(str: String, index: Int) -> String {
        let char = String(str[str.index(str.startIndex, offsetBy: index)..<str.index(str.startIndex, offsetBy: index+1)])
        return char
    }
    
    func displayChoicesRandomly() {
        if (currentCharIndex==0 || currentCharIndex < ansLen) {
            if let answer = quiz.answerInKana {
                ansChar = strAccess(str: answer, index: currentCharIndex)  // 正解の文字
                var ansIndex = Int.random(in: 0 ..< 4)  // 正解が入る場所(1-4)
                answerChoices[ansIndex] = ansChar
                generateChoicesRandomly()
                for i in 0..<4 {
                    DispatchQueue.main.async {
                        self.ansButtonArray[i].setTitle(self.answerChoices[i], for: .normal)
                    }
                }
                // 次の文字列
                currentCharIndex += 1
            }else if (currentCharIndex == ansLen) {
                // MARK: ボタンを消す
                DispatchQueue.main.async {
                    self.stackButtons.isHidden = true
                }
                
                print("正解")
                
                
            }
        } else {
            print("quizが存在しない or \(currentCharIndex)")
        }
        
    }
    
    func generateChoicesRandomly() {
        
        let hira:String = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
        let kata:String = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
        let alpha:String = "abcdefghijklmnopqrstuvwxyz"
        let num:String = "0123456789"
        
        var tmp = ""  // 答えの文字の種類の要素一覧
        if (hira.contains(ansChar)) {
            tmp = hira
        } else if (kata.contains(ansChar)) {
            tmp = kata
        } else if (alpha.contains(ansChar)) {
            tmp = alpha
        } else {
            tmp = num
        }
        //tmpLenとは ランダム文字の長さ
        var tmpLen = tmp.count
        
        //この部分でanswerChoices[String]を当てはめている
        for i in 0..<4 {
            while (answerChoices[i] == "") {
                var index = Int.random(in: 0 ..< tmpLen)
                //あいうえお、アイウエオのどれかの文字
                var choice = strAccess(str: tmp, index: index)
                //重複した文字列がはいっていなければ、
                if (!answerChoices.contains(choice)){
                    answerChoices[i] = choice
                }
            }
        }
    }
    
    
    
}

//読みあげ機能
extension PlayViewController {
    
    func displaySentence() {
        yomiageTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(showDelayText(time:)), userInfo: quiz.question, repeats: true)
    }
    
    @objc func showDelayText(time: Timer) {
        let message = time.userInfo as! String
        questionSentence.text = String(message.prefix(currentCharNum))
        if message.count <= currentCharNum {
            time.invalidate()
            currentCharNum = 0
            return
        }
        currentCharNum += 1
    }
}

//残り時間機能
extension PlayViewController {
    
    //タイマーの中身
    @objc func timerFunc() {
        // prgの現在の数値より少しだけ少ない数値をprgにセット
        let newValue = prg.progress - 0.01
        // 10秒ぐらいで0になりますので
        if (newValue < 0) {
            // newValueが０より小さくなってしまったら
            prg.setProgress(0, animated: true)
            // タイマーを停止させます
            timerPrg.invalidate()
        } else {
            prg.setProgress(newValue, animated: true)
        }
    }
    
    func progress() {
        //タイマーの初期化
        timerPrg.invalidate()
        prg.progress = 1.0
        //バーがだんだん短くなっていくようにTimerでリピートさせる
        timerPrg = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(timerFunc), userInfo: nil, repeats: true)
    }
    
    @IBAction func showIndicator(_ sender: Any) {
        progress()
    }
    
    
    
}
