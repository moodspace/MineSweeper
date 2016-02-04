//
//  ViewController.swift
//  The Dead Locker
//
//  Created by Ke Qian on 11/30/15.
//  Copyright © 2015 MoodSpace. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum defaultsKeys {
        static let best = "-1|-1|-1|-1|-1|-1"
        static let others = "-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1$-1|-1|-1|-1|-1|-1"
    }
    
    var leaderLabelsArray: [UILabel] = []
    
    var cheatsCounter = 0
    
    let screenSize = UIScreen.mainScreen().bounds
    var squareMargin = CGFloat(0)
    var squareSize = CGFloat(0)
    let viewPadding = CGFloat(10)
    let boardMargin = CGFloat(10)
    
    // boardSize, mines, tilesLeft, score, time, difficulty
    // Difficulty = 0 - 20
    // Real difficulty depends on board size as well
    var stat = [10, 0, 0, 0, 0, 0]
    
    var timer = NSTimer()
    // var delayTimer = NSTimer()
    var minesArray: [Bool] = []
    var mineStatesArray: [Bool] = []
    var mineButtonsArray: [UIButton] = []
    
    let animationDelayConst = 0.05
    
    
    func newGame(diff : Int, size : Int, startNow : Bool) {
        assert(size > 0)
        assert(diff >= 0)
        assert(diff <= 20)
        
        newGameButton.title = "New"
        prompt.text = " "
        hideStuff(diffPicker)
        showStuff(sliderLabel, delay: 1)
        showStuff(slider, delay: 1)
        
        squareSize = ((min(screenSize.width, screenSize.height) - viewPadding * 2) - boardMargin * 2) / CGFloat(stat[0])
        squareMargin = CGFloat(squareSize / 20)
        // Stop infinite firing with delay timer
        newGameButton.enabled = false
        
        stat[0] = size
        stat[5] = diff
        
        // Fade out previous mines row by row
        for i in 0...stat[0]-1 {
            for j in 0...stat[0]-1 {
                if (i * self.stat[0] + j >= mineButtonsArray.count) {
                    continue
                }
                let button = self.mineButtonsArray[i * self.stat[0] + j]
                if (!minesArray[i * self.stat[0] + j]) {
                    // is not a mine, hide then (to show losses)
                    UIView.animateWithDuration(0.5,
                        delay: animationDelayConst / 10 * Double(i * stat[0]),
                        options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                        animations: {
                            let oldFrame = button.frame
                            button.frame = CGRect(x: oldFrame.origin.x + oldFrame.width / 2, y: oldFrame.origin.y + oldFrame.height / 2, width: 1, height: 1)
                        }, completion: nil)
                } else {
                    button.setTitle("💥", forState: UIControlState.Normal)
                    UIView.animateWithDuration(0.1,
                        delay: 0,
                        options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                        animations: {
                            button.layer.borderWidth = 0
                            button.backgroundColor = UIColor(red:0.19, green:0.13, blue:0.13, alpha:1.0)
                        }, completion: nil)
                }
                
                UIView.animateWithDuration(0.5,
                    delay: animationDelayConst / 10 * Double(i * stat[0]),
                    options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                    animations: {
                        self.mineButtonsArray[i * self.stat[0] + j].alpha = 0
                    }, completion: nil)
            }
        }
        
        if (startNow) {
            startNewGame()
        } else {
            newGameButton.enabled = true
            showLeaderBoard()
        }
    }
    
    
    func printScore(stat : [Int]) -> String {
        // boardSize, mines, tilesLeft, score, time, difficulty
        let score = String(stat[3]).stringByPaddingToLength(9,
            withString: " ",
            startingAtIndex: 0)
        
        let board = String(format: "%dx%d", stat[0], stat[0]).stringByPaddingToLength(10,
            withString: " ",
            startingAtIndex: 0)
        
        let mines = String(stat[1]).stringByPaddingToLength(9,
            withString: " ",
            startingAtIndex: 0)
        
        let time = String(format: "%02d:%02d", stat[4] / 60, stat[4] % 60).stringByPaddingToLength(10,
            withString: " ",
            startingAtIndex: 0)
        
        return String(score + board + mines + time)
    }
    
    /* Init all game elements, called only after newGame() which cleans last game */
    func startNewGame () {
        // Kill the delay timer
        // delayTimer.invalidate();
        // Also suppose user decides New Game before hits a mine
        timer.invalidate();
        
        // Dispose junks
        for btn in mineButtonsArray {
            btn.removeFromSuperview()
        }
        
        // Reset stats & mines
        
        minesArray.removeAll()
        mineStatesArray.removeAll()
        mineButtonsArray.removeAll()
        
        // Setting up layout
        topBar.prompt = "The Dead Locker"
        topBar.title = nil
        // Only hide at this stage, unlike picker, user has no control of its hiding / showing
        hideStuff(sliderLabel)
        hideStuff(slider)
        
        // Hide leaderboard
        for label in leaderLabelsArray {
            hideStuff(label)
        }
        
        let topRegionHeight = self.navigationController!.navigationBarHidden ? 0 :
            CGFloat(70) + self.navigationController!.navigationBar.frame.size.height
        
        // Creating mines
        let mineCounter = Int(Double(stat[0] * stat[0]) / Double(30) * Double(stat[5]))
        if (mineCounter > 0) {
            for _ in 0...mineCounter-1 {
                minesArray.append(true)
            }
        }
        while minesArray.count < stat[0]*stat[0] {
            minesArray.append(false)
        }
        
        minesArray.shuffleInPlace(); // in place shuffling mines vector
        
        print(cheatsCounter)
        
        // Generating mine buttons
        for i in 0...stat[0]-1 {
            for j in 0...stat[0]-1 {
                let button   = UIButton(type: UIButtonType.System) as UIButton
                button.frame = CGRectMake(
                    viewPadding + boardMargin + CGFloat(j) * squareSize + squareMargin,
                    topRegionHeight + viewPadding + boardMargin + CGFloat(i) * squareSize + squareMargin,
                    squareSize - 2 * squareMargin, squareSize - 2 * squareMargin)
                if (minesArray[i * stat[0] + j]) {
                    // mine
                    button.backgroundColor = UIColor(red: 0.20, green: 0.6, blue: 0.85, alpha: 1.0)
                    if (cheatsCounter > 50) {
                        // MAY THE CHEATS BE WITH YOU
                        button.backgroundColor = UIColor(red:0.34, green:0.56, blue:0.7, alpha:1.0)
                    }
                    button.addTarget(self, action: "triggerMineAction:", forControlEvents: UIControlEvents.TouchUpInside)
                    button.alpha = 0
                } else {
                    // safe
                    button.backgroundColor = UIColor(red: 0.20, green: 0.6, blue: 0.85, alpha: 1.0)
                    button.addTarget(self, action: "triggerSafeAction:", forControlEvents: UIControlEvents.TouchUpInside)
                    button.alpha = 0
                }
                button.setTitle("", forState: UIControlState.Normal)
                button.layer.cornerRadius = squareSize / 5
                button.layer.borderWidth = 1
                button.layer.borderColor = UIColor(red: 0.16, green: 0.5, blue: 0.73, alpha: 1.0).CGColor
                button.titleLabel!.font = button.titleLabel!.font.fontWithSize(squareSize/2)
                
                mineButtonsArray.append(button)
                mineStatesArray.append(false)
            }
        }
        
        cheatsCounter = 0
        
        // Start filling buttons immediately
        fillViewRecurse((stat[0] - 1) / 2, col: (stat[0] - 1) / 2, delay: 0)
        
        // Stats server init
        // boardSize, mines, tilesLeft, score, time, difficulty
        stat = [stat[0], mineCounter, stat[0] * stat[0], 0, 0, stat[5]]
        
        // Master timer init
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerTick", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        
        // Now user can restart the game
        newGameButton.enabled = true
        newGameButton.title = "End"
        prompt.text = "🤔"
    }
    
    func fillViewRecurse(row : Int, col : Int, delay : Int) {
        // print("Rendering mine " + String(row) + ", " + String(col))
        
        let centerRowCol = (stat[0] - 1) / 2
        
        if (!mineStatesArray[row * stat[0] + col]) {
            // Mark as visited
            mineStatesArray[row * self.stat[0] + col] = true;
            // Animate
            UIView.animateWithDuration(0.5,
                delay: animationDelayConst * Double(delay),
                options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                animations: {
                    self.mineButtonsArray[row * self.stat[0] + col].alpha = 1
                }, completion: nil)
            // Add the button with animation
            self.view.addSubview(self.mineButtonsArray[row * self.stat[0] + col])
            // Visit outer neighbors (4 direction)
            if (row <= centerRowCol && row > 0) {
                // North
                fillViewRecurse(row-1,  col: col, delay: delay+1)
            }
            if (col >= centerRowCol && col + 1 < stat[0]) {
                // East
                fillViewRecurse(row,  col: col+1, delay: delay+1)
            }
            if (row >= centerRowCol && row + 1 < stat[0]) {
                // South
                fillViewRecurse(row+1,  col: col, delay: delay+1)
            }
            if (col <= centerRowCol && col > 0) {
                // West
                fillViewRecurse(row,  col: col-1, delay: delay+1)
            }
        }
    }
    
    func gameOver(msg : String) {
        timer.invalidate()
        
        topBar.prompt = nil
        topBar.title = "The Dead Locker"
        status.text = " "
        
        let alert = UIAlertController(title: "Game over", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        
        let acceptAction = UIAlertAction(title: "Okay cool", style: UIAlertActionStyle.Default) {
            (_) -> Void in self.newGame(self.stat[5], size: self.stat[0], startNow: false)
        }
        
        alert.addAction(acceptAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timerTick() {
        // boardSize, mines, tilesLeft, score, time, difficulty
        stat[4]++
        topBar.title = String(format: "%02d : %02d", stat[4] / 60, stat[4] % 60)
        if (prompt.text == "😍") {
            prompt.text = "😘"
        } else if (prompt.text == "😘") {
            prompt.text = "🤔"
        }
        
        if (stat[4] % 10 == 7) {
            UIView.animateWithDuration(0.5,
                delay: 0,
                options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                animations: {
                    self.prompt.transform = CGAffineTransformMakeRotation((10.0 * CGFloat(M_PI)) / 180.0)
                }, completion: { _ in
                    UIView.animateWithDuration(0.3,
                        delay: 0,
                        options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                        animations: {
                            self.prompt.transform = CGAffineTransformMakeRotation((-20.0 * CGFloat(M_PI)) / 180.0)
                        }, completion: { _ in
                            UIView.animateWithDuration(0.3,
                                delay: 0,
                                options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                                animations: {
                                    self.prompt.transform = CGAffineTransformMakeRotation(0.0)
                                }, completion: nil
                            )
                        }
                    )
                }
            )
        }
        
        status.text = String(format: "%d x %d \t Mines: %d \t Unchecked: %d \t Score: %d", stat[0], stat[0], stat[1], stat[2], stat[3])
    }
    
    func triggerMineAction(sender:UIButton!)
    {
        // tile animation
        animateTileClicked(sender, sequence: 0)
        
        prompt.text = "😵"
        
        // boardSize, mines, tilesLeft, score, time, difficulty
        stat[2]--
        
        sender.layer.borderWidth = 0
        sender.setTitle("💥", forState: UIControlState.Normal)
        sender.backgroundColor = UIColor(red:0.19, green:0.13, blue:0.13, alpha:1.0)
        
        // Deactivate so no duplicate firing
        sender.enabled = false
        
        gameOver("You are killed by a mine after " + String(stat[4]) + " seconds!")
        
        let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("grenade", ofType: "mp3")!)
        var audioPlayer = AVAudioPlayer()
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: sound, fileTypeHint: AVFileTypeMPEGLayer3)
            audioPlayer.numberOfLoops = 28
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {
            print("Error")
        }
    }
    
    /* for animation purpose, need to know depth of recursion */
    func triggerSafeActionWithDelay(sender:UIButton!, delay:Int) {
        // shake animation
        animateTileClicked(sender, sequence: delay)
        // get all 8 surroundings
        let surroundingMines = detectSurrounding(mineButtonsArray.indexOf(sender)!)
        
        prompt.text = "😍"
        
        // boardSize, mines, tilesLeft, score, time, difficulty
        stat[2]--
        stat[3] += stat[0] * stat[5]
        if (stat[2] <= stat[1]) {
            // game well done
            prompt.text = "🖖"
            gameOver("You cleared the minefield in " + String(stat[4]) + " seconds!")
            let defaults = NSUserDefaults.standardUserDefaults()
            
            print("Winning: " + serializeArray(stat))
            
            let best = deserializeArray(defaults.stringForKey(defaultsKeys.best))
            var others = deserializeMatrix(defaults.stringForKey(defaultsKeys.others))
            if (compareRecords(stat, r2: best)) {
                others.insert(best, atIndex: 0)
                others.removeLast()
                defaults.setValue(serializeMatrix(others), forKey: defaultsKeys.others)
                defaults.setValue(serializeArray(stat), forKey: defaultsKeys.best)
            } else {
                var newOthers : [[Int]] = []
                var inserted = false
                for other in others {
                    if (!inserted && compareRecords(stat, r2: other)) {
                        inserted = true
                        newOthers.append(stat)
                    }
                    if (newOthers.count < others.count) {
                        newOthers.append(other)
                    }
                }
                defaults.setValue(serializeMatrix(newOthers), forKey: defaultsKeys.others)
            }
            
            defaults.synchronize()
        }
        
        // show surrounding mines if not zero
        sender.setTitle(surroundingMines == 0 ? "" : String(surroundingMines), forState: UIControlState.Normal)
        
        // Deactivate so no duplicate firing
        sender.enabled = false
        
        // if all 8 are clear, then clear them, and recurse
        if surroundingMines == 0 {
            for tile in getSurrounding(mineButtonsArray.indexOf(sender)!) {
                if tile.enabled {
                    triggerSafeActionWithDelay(tile, delay: delay+1)
                }
            }
        }
    }
    
    func triggerSafeAction(sender:UIButton!)
    {
        triggerSafeActionWithDelay(sender, delay: 0)
    }
    
    func animateTileClicked(tile : UIButton, sequence : Int) {
        // show currently animated on top
        self.view.bringSubviewToFront(tile)
        // old frame to restore to
        let oldFrame = tile.frame
        
        UIView.animateWithDuration(0.2,
            delay: Double(sequence) / 100,
            options: [UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
            animations: {
                tile.frame = CGRect(x: oldFrame.origin.x - oldFrame.width / 10, y: oldFrame.origin.y - oldFrame.height / 10, width: oldFrame.width * 6 / 5, height: oldFrame.height * 6 / 5)
                // fade color to grey
                tile.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0)
            }, completion: { _ in
                UIView.animateWithDuration(0.5,
                    delay: 0,
                    options: [UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
                    animations: {
                        tile.frame = oldFrame
                        // thin out border
                        tile.layer.borderWidth = 0
                    }, completion: nil
                )
            }
        )
    }
    
    func detectSurrounding (index : Int) -> Int {
        let row = index / stat[0]
        let col = index % stat[0]
        return
            getMineState(row-1, col: col-1) + getMineState(row-1, col: col) + getMineState(row-1, col: col+1) +
                getMineState(row, col: col-1) + getMineState(row, col: col+1) +
                getMineState(row+1, col: col-1) + getMineState(row+1, col: col) + getMineState(row+1, col: col+1)
    }
    
    /* while calling, assume all surrounding tiles are clear */
    func getSurrounding (index : Int) -> [UIButton] {
        let row = index / stat[0]
        let col = index % stat[0]
        var tiles :  [UIButton?] = []
        tiles += [
            getMine(row-1, col: col-1), getMine(row-1, col: col), getMine(row-1, col: col+1),
            getMine(row, col: col+1), getMine(row+1, col: col+1), getMine(row+1, col: col),
            getMine(row+1, col: col-1), getMine(row, col: col-1)
        ]
        return tiles.flatMap{$0}
    }
    
    func compareRecords(r1 : [Int], r2 : [Int]) -> Bool {
        // boardSize, mines, tilesLeft, score, time, difficulty
        if (r1[3] > r2[3]) {
            // better score
            return true
        } else if (r1[3] == r2[3]) {
            if (r1[4] < r2[4]) {
                // less time
                return true
            } else if (r1[4] == r2[4]) {
                if (r1[5] > r2[5]) {
                    // higher level
                    return true
                } else if (r1[5] == r2[5]) {
                    if (r1[0] > r2[0]) {
                        // bigger board!!!
                        return true
                    }
                }
            }
        }
        return false
    }
    
    
    func serializeMatrix(matrix : [[Int]]) -> String {
        var result = ""
        var counter = 0
        for row in matrix {
            result += serializeArray(row)
            if (++counter < matrix.count) {
                result += "$"
            }
        }
        print(result)
        return result
    }
    
    func serializeArray(array : [Int]) -> String {
        var result = ""
        var counter = 0
        for col in array {
            result += String(col)
            if (++counter < array.count) {
                result += "|"
            }
        }
        return result.substringToIndex(result.endIndex)
    }
    
    func deserializeMatrix(string : String?) -> [[Int]] {
        if string == nil {
            return [
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1],
                [-1, -1, -1, -1, -1, -1]
            ]
        }
        var result: [[Int]] = []
        let splitResult = string!.characters.split{$0 == "$"}.map(String.init)
        for row in splitResult {
            result.append(deserializeArray(row))
        }
        print(result)
        return result
    }
    
    func deserializeArray(string : String?) -> [Int] {
        if string == nil {
            return [-1, -1, -1, -1, -1, -1]
        }
        let splitRow = string!.characters.split{$0 == "|"}.map(String.init)
        var splitRowResult : [Int] = []
        for s in splitRow {
            splitRowResult.append(Int(s)!)
        }
        return splitRowResult
    }
    
    /* 0 if tile is out of bound or has no mine */
    func getMineState(row : Int, col : Int) -> Int {
        if (row < 0 || row >= stat[0] || col < 0 || col >= stat[0]) {
            return 0
        }
        return minesArray[row*stat[0]+col] ? 1 : 0
    }
    
    /* nil if tile is out of bound */
    func getMine(row : Int, col : Int) -> UIButton? {
        if (row < 0 || row >= stat[0] || col < 0 || col >= stat[0]) {
            return nil
        }
        return mineButtonsArray[row*stat[0]+col]
    }
    
    @IBOutlet weak var topBar: UINavigationItem!
    @IBOutlet weak var newGameButton: UIBarButtonItem!
    @IBOutlet weak var pickLevelButton: UIBarButtonItem!
    @IBOutlet weak var prompt: UILabel!
    
    @IBAction func newGameButtonClicked(sender: UIBarButtonItem) {
        if (sender.title == "End") {
            gameOver("Game stopped at " + String(stat[4]) + " seconds!")
        } else {
            newGame(self.stat[5], size: self.stat[0], startNow: true)
        }
    }
    
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var diffPicker: UIPickerView!
    @IBOutlet weak var status: UILabel!
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        self.stat[0] = Int(sender.value)
        topBar.title = "New size: " + String(stat[0]) + " x " + String(stat[0])
    }
    
    @IBAction func pickLevelButtonClicked(sender: UIBarButtonItem) {
        if (timer.valid) {
            // Do nothing if in game
            return
        }
        
        // MAY THE CHEATS BE WITH YOU
        cheatsCounter++
        
        if (self.diffPicker.hidden && diffPicker.alpha < 0.000001) {
            for label in leaderLabelsArray {
                hideStuff(label)
            }
            // Delay update causes issue
            newGameButton.enabled = false
            showStuff(self.diffPicker, delay: 1)
        } else {
            // Re-enable
            newGameButton.enabled = true
            hideStuff(diffPicker)
            for label in leaderLabelsArray {
                showStuff(label, delay: 1)
            }
        }
    }
    
    /* optionally we wish to show stuff some seconds later (e.g. after another hiding) */
    func showStuff(stuff : UIView, delay : Int) {
        stuff.alpha = 0
        stuff.hidden = false
        
        UIView.animateWithDuration(0.5,
            delay: Double(delay),
            options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
            animations: {
                stuff.alpha = 1
            }, completion: nil)
    }
    
    func hideStuff (stuff : UIView) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            options: [UIViewAnimationOptions.CurveLinear ,UIViewAnimationOptions.AllowUserInteraction,UIViewAnimationOptions.BeginFromCurrentState],
            animations: {
                stuff.alpha = 0
            }, completion: { _ in
                stuff.hidden = true
        })
    }
    
    let pickerDataDiff = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    // let pickerDataSize = [1, 5, 9, 13, 17, 21, 25, 32, 64, 128, 256, 512]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Hidden elements
        diffPicker.hidden = true
        diffPicker.dataSource = self
        diffPicker.delegate = self
        
        showLeaderBoard()
    }
    
    func showLeaderBoard() {
        leaderLabelsArray.removeAll()
        
        // User data
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // Leaderboard
        var leaderCounter = 0
        
        let label = UILabel(frame: CGRect(x: viewPadding, y: CGFloat(90), width: screenSize.width - 2 * viewPadding, height: CGFloat(40)))
        label.textAlignment = NSTextAlignment.Center
        label.text = "👉Leaderboard👈"
        label.font = UIFont(name: "Menlo-Bold", size: 15.0)
        leaderLabelsArray.append(label)
        self.view.addSubview(label)
        
        let labelHeader = UILabel(frame: CGRect(x: viewPadding, y: CGFloat(125), width: screenSize.width - 2 * viewPadding, height: CGFloat(20)))
        labelHeader.font = UIFont(name: "Menlo-Bold", size: 13.0)
        labelHeader.textAlignment = NSTextAlignment.Center
        labelHeader.text = "Score    Board     Mines    Time      "
        leaderLabelsArray.append(labelHeader)
        self.view.addSubview(labelHeader)
        
        let best = deserializeArray(defaults.stringForKey(defaultsKeys.best))
        if (best[0] > 0) {
            let label = UILabel(frame: CGRect(x: viewPadding, y: CGFloat(leaderCounter * 20 + 135), width: screenSize.width - 2 * viewPadding, height: CGFloat(40)))
            label.font = UIFont(name: "Menlo-Bold", size: 13.0)
            label.textAlignment = NSTextAlignment.Center
            if (best[0] > 0) {
                label.text = " " + printScore(best)
            } else {
                label.text = "❓"
            }
            leaderLabelsArray.append(label)
            label.alpha = 0
            showStuff(label, delay: leaderCounter)
            self.view.addSubview(label)
            leaderCounter++
        }
        
        for other in deserializeMatrix(defaults.stringForKey(defaultsKeys.others)) {
            
            let label = UILabel(frame: CGRect(x: viewPadding, y: CGFloat(leaderCounter * 20 + 135), width: screenSize.width - 2 * viewPadding, height: CGFloat(40)))
            label.font = UIFont(name: "Menlo-Bold", size: 13.0)
            label.textAlignment = NSTextAlignment.Center
            if (other[0] > 0) {
                label.text = " " + printScore(other)
            } else {
                label.text = "❓"
            }
            leaderLabelsArray.append(label)
            label.alpha = 0
            showStuff(label, delay: leaderCounter)
            self.view.addSubview(label)
            leaderCounter++
            
        }
        
    }
    
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataDiff.count
    }
    
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(pickerDataDiff[row])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.pickLevelButton.title = "Level " + String(pickerDataDiff[row])
        self.stat[5] = pickerDataDiff[row]
    }
}

extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}


