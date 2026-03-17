//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import MetalKit

class IgniterScene: SceneProtocol {
    private var wordRenderer: WordRenderer!
    private var cameraSettings: CameraSettings!
    private var camera: Camera!
    private var device: MTLDevice!
    private var currentFooIndex: Int
    private var timeToAnswer: Double
    private var wordTimeToLive: Double
    private var gameElapsedTime: Double
    private var streakChain: Int
    private var currentAnswerWindow: Double
    private var gameState: GameState!
    private var WordFoos = [WordFoo]()
    
    // -- Local Game Track
    private var score: Double = 0
    private var combo: Int = 0

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
    
    let wordBank: [String] = [
        "I", "you", "we", "they", "she", "he", "it", "have", "has", "do", "does", "say", "says",
        "be", "to", "of", "a", "and", "in", "that", "for", "not", "on", "with", "her", "from",
        "an", "will", "my", "one", "all", "there", "what", "so", "up", "out", "if", "about",
        "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "likes",
        "goes", "gets", "makes", "no", "just", "him", "know", "take", "takes", "people",
        "into", "your", "good", "some", "could", "them", "see", "sees", "other", "than",
        "then", "now", "look", "looks", "only", "come", "comes", "over", "its", "think",
        "also", "back", "after", "use", "uses", "two", "how", "our", "work", "works", "first",
        "well", "way", "even", "new", "want", "wants", "because", "any", "these", "give",
        "day", "days", "most", "us", "knows", "find", "finds", "gives", "tell", "tells",
        "am", "are", "is", "call", "calls", "asks", "need", "needs", "feel", "feels",
        "become", "becomes", "leave", "leaves", "put", "puts", "mean", "means", "keep",
        "keeps", "let", "lets", "begin", "begins", "help", "helps", "show", "shows", "hear",
        "hears", "play", "plays", "run", "move", "moves", "live", "lives", "believe",
        "believes", "hold", "holds", "bring", "brings", "happen", "happens", "write",
        "writes", "sit", "sits", "stand", "stands", "lose", "loses", "pay", "pays", "meet",
        "meets", "include", "includes", "continue", "continues", "set", "sets", "learn",
        "learns", "change", "changes", "apple", "away", "alright", "amazing", "adjust",
        "alarm", "ball", "bat", "basket", "bag", "book", "build", "builds", "balance",
        "cat", "close", "consider", "considers", "cover", "cancel", "choose", "chooses",
        "dog", "dream", "drive", "drives", "destroy", "destroys", "elephant", "easy", "egg",
        "enter", "enters", "extra", "exam", "experience", "face", "fear", "fun", "fish",
        "follow", "follows", "focus", "flow", "game", "great", "gather", "gathers", "horse",
        "hello", "his", "their", "harm", "heat", "ice", "idea", "joke", "jam", "kind",
        "king", "kick", "light", "listen", "listens", "label", "mom", "meeting", "never",
        "night", "name", "notice", "negotiate", "once", "another", "order", "own", "object",
        "offer", "operate", "operates", "observe", "obtain", "obtains", "park", "pretty",
        "pet", "plan", "quiet", "question", "quite", "quit", "quits", "red", "rain", "reply",
        "stop", "stops", "sweet", "small", "sleep", "supply", "separation", "toy", "tall",
        "thinks", "travel", "train", "target", "transfer", "transfers", "under", "until",
        "understand", "understands", "upload", "uploads", "urge", "voice", "vote", "verify",
        "verifies", "vary", "venture", "value", "view", "watch", "walk", "walks", "warm",
        "weight", "warning", "welcome", "yes", "young", "yield", "zebra", "zip", "zero",
        "zoom", "zoo", "zone", "internet", "online", "offline", "price", "cost", "payment",
        "interest", "web", "phone", "message", "messages", "film", "reel", "reels", "films",
        "video", "videos", "unlock", "lock", "ad", "add", "mix", "cut", "edit", "mixes",
        "cuts", "edits", "ads", "adds", "try", "tries", "toys", "maintain", "maintains",
        "connection", "connections", "main", "secondary", "monitor", "monitors", "screen",
        "screens", "movie", "movies", "water", "ocean", "sea", "lake", "river", "rivers",
        "seas", "lakes", "oceans", "mountain", "mountains", "hill", "hills", "banana",
        "bread", "apples", "bananas", "eggs", "fiber", "avocado", "avocados", "pineapple",
        "peanuts", "leg", "legs", "arms", "arm", "eye", "eyes", "finger", "fingers", "toe",
        "toes", "shoulder", "shoulders", "foot", "feet", "heel", "heels", "abdomen", "head",
        "ear", "ears", "hair", "hand", "hands", "open", "opens", "closes", "closed",
        "don't", "doesn't", "engine", "engines", "balls", "net", "nets", "racket",
        "rackets", "pool", "pools", "court", "courts", "shoe", "shoes", "coffee", "sugar",
        "tree", "trees", "glass", "plate", "spoon", "fork", "spoons", "forks", "pencil",
        "pencils", "pens", "pen", "paper", "papers", "medicine", "remedy", "remedies",
        "pill", "pills", "capsule", "capsules", "blood", "vaccine", "vaccines", "immunity",
        "disease", "diseases", "conditions", "condition", "supermarket", "market", "store",
        "stores", "markets", "supermarkets", "sandals", "belt", "belts", "recovery",
        "recover", "recovers", "plants", "plant", "table", "tables", "chart", "charts",
        "chair", "chairs", "desk", "job", "works", "jobs", "cup", "cups", "pan", "pans",
        "pot", "pots", "cats", "dogs", "sidewalk", "salt", "stove", "stoves", "oven",
        "ovens", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
        "twelve", "thirteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
        "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety",
        "cook", "cooks", "number", "numbers", "chicken", "cow", "sensor", "sensors",
        "activate", "activates"
    ]

    init(device: MTLDevice, view: MTKView, gameState: GameState,
         currentFooIndex: Int = 0, isGameOver: Bool = false, isPaused: Bool = false,
         score: Double = 0, strikeCount: Int = 0) {
        self.device = device
        self.gameState = gameState
        self.currentFooIndex = currentFooIndex
        self.timeToAnswer = 0
        self.wordTimeToLive = 0
        self.currentAnswerWindow = 0
        self.gameElapsedTime = 0
        self.streakChain = 0
        buildInitialScene(view: view)
    }
    
    func buildInitialScene(view: MTKView) {
        cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: 19.5/9,
            nearZ: 1.0,
            farZ: 1000.0)
        
        for word in wordBank {
            WordFoos.append(WordFoo(Word: word, Reward: 1))
        }
        
        
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device, screenWidth: Float(view.bounds.width)) 
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        if gesture.state == .began {
            lastPanLocation = location
        } else if gesture.state == .changed {
            let delta = CGPoint(x: location.x - lastPanLocation.x, y: location.y - lastPanLocation.y)
            lastPanLocation = location
        }
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }
    
    func nextFoo(reward: Int) {
        score += Double(reward)
        currentFooIndex = (currentFooIndex + 1) % WordFoos.count //
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
    }
    
    func resetTimers() {
        timeToAnswer = 0
        wordTimeToLive = 0
        gameState.IsAnswering = false
    }
    
    // -- Encode is called by update.
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        if gameState.CurrentState == .running {
            gameElapsedTime += Double(gameState.Timer.getTickSeconds())
            if !gameState.IsAnswering {
                wordTimeToLive += Double(gameState.Timer.getTickSeconds())
                // print("Elapsed time while NOT answering: \(wordTimeToLive) -- \(WordFoos[currentFooIndex])")
                if wordTimeToLive > gameState.WordTimeToLive {
                    nextFoo(reward: 0)
                    resetTimers()
                    streakChain = 0
                }
            } else if gameState.CorrectAnswer {
                nextFoo(reward: WordFoos[currentFooIndex].Reward)
                gameState.IsAnswering = false
                gameState.CorrectAnswer = false
                resetTimers()
                streakChain += 1;
                // print("correct Answer, moving onto next...")
            } else {
                timeToAnswer += Double(gameState.Timer.getTickSeconds())
                if timeToAnswer >= gameState.WordTimeToAnswer {
                    gameState.IsAnswering = false
                    nextFoo(reward: 0)
                    streakChain = 0
                    resetTimers()
                    return
                }
                gameState.CorrectAnswer = WordFoos[currentFooIndex].Word.compare(gameState.CapturedAnswer, options: .caseInsensitive) == .orderedSame
                // print("Player is taking time to answer.... \(gameState.CapturedAnswer)")
            }
            if gameElapsedTime >= gameState.LevelDuration {
                gameState.CurrentState = .stop
                wordRenderer.CurrentFoo = WordFoo(Word: "Game Over", Reward: 0)
            }
            print("streak:\(combo)")
        }
       
        if streakChain == gameState.MaxStreak + 1 {
            score *= 1.5
            streakChain = 0
        }
        
        gameState.Score = Int(score)
        gameState.Streak = streakChain
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
}
