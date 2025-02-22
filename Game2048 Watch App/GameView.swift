//
//  ContentView.swift
//  Game2048 Watch App
//
//  Created by Show on 2025/2/22.
//

import SwiftUI

struct GameView: View {
    @StateObject private var gameModel = GameModel()
    @SceneStorage("bestScore") private var bestScore = 0
    
    var body: some View {
        VStack(spacing: 8) {
            
            // 分數面板
            HStack(spacing: 8) {
                ScoreView(title: "SCORE", score: gameModel.score)
                ScoreView(title: "BEST", score: max(bestScore, gameModel.score))
            }
            
            // 遊戲網格
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "bbada0"))
                    .padding(2)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                    ForEach(0..<16) { index in
                        let row = index / 4
                        let col = index % 4
                        CellView(number: gameModel.board[row][col])
                    }
                }
                .padding(4)
            }
            .gesture(DragGesture()
                .onEnded { gesture in
                    let dx = gesture.translation.width
                    let dy = gesture.translation.height
                    
                    if abs(dx) > abs(dy) {
                        if dx > 0 {
                            gameModel.move(.right)
                        } else {
                            gameModel.move(.left)
                        }
                    } else {
                        if dy > 0 {
                            gameModel.move(.down)
                        } else {
                            gameModel.move(.up)
                        }
                    }
                    
                    // 更新最高分
                    bestScore = max(bestScore, gameModel.score)
                }
            )
            
            // 新遊戲按鈕
            Button(action: {
                gameModel.resetGame()
            }) {
                Text("New Game")
                    .font(.system(.headline))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "8f7a66"))
                    .cornerRadius(6)
            }
        }
        .padding(8)
        .background(Color(hex: "faf8ef"))
    }
}

struct ScoreView: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            Text("\(score)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(minWidth: 60)
        .padding(.vertical, 4)
        .background(Color(hex: "bbada0"))
        .cornerRadius(4)
    }
}

struct CellView: View {
    let number: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
            
            if number > 0 {
                Text("\(number)")
                    .font(.system(size: number > 512 ? 14 : 18, weight: .bold))
                    .foregroundColor(number <= 4 ? Color(hex: "776e65") : .white)
            }
        }
        .frame(height: 35)
    }
    
    private var backgroundColor: Color {
        switch number {
        case 0: return Color(hex: "cdc1b4")
        case 2: return Color(hex: "eee4da")
        case 4: return Color(hex: "ede0c8")
        case 8: return Color(hex: "f2b179")
        case 16: return Color(hex: "f59563")
        case 32: return Color(hex: "f67c5f")
        case 64: return Color(hex: "f65e3b")
        case 128: return Color(hex: "edcf72")
        case 256: return Color(hex: "edcc61")
        case 512: return Color(hex: "edc850")
        case 1024: return Color(hex: "edc53f")
        case 2048: return Color(hex: "edc22e")
        default: return Color(hex: "3c3a32")
        }
    }
}

// 用於支援十六進制顏色代碼的擴展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 遊戲模型
class GameModel: ObservableObject {
    @Published var board: [[Int]]
    @Published var score: Int
    
    enum Direction {
        case up, down, left, right
    }
    
    init() {
        board = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        addNewNumber()
        addNewNumber()
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        addNewNumber()
        addNewNumber()
    }
    
    private func addNewNumber() {
        var emptyCells = [(Int, Int)]()
        
        for row in 0..<4 {
            for col in 0..<4 {
                if board[row][col] == 0 {
                    emptyCells.append((row, col))
                }
            }
        }
        
        if let (row, col) = emptyCells.randomElement() {
            board[row][col] = Int.random(in: 1...10) <= 9 ? 2 : 4
        }
    }
    
    func move(_ direction: Direction) {
        let oldBoard = board
        var moved = false
        
        switch direction {
        case .up:
            moved = moveUp()
        case .down:
            moved = moveDown()
        case .left:
            moved = moveLeft()
        case .right:
            moved = moveRight()
        }
        
        if moved {
            addNewNumber()
        }
        
        // 檢查遊戲結束
        if isGameOver() {
            print("Game Over!")
        }
    }
    
    private func moveLeft() -> Bool {
        var moved = false
        for row in 0..<4 {
            var col = 0
            while col < 3 {
                if board[row][col] == 0 {
                    // 找到下一個非零數字
                    var nextCol = col + 1
                    while nextCol < 4 && board[row][nextCol] == 0 {
                        nextCol += 1
                    }
                    if nextCol < 4 {
                        board[row][col] = board[row][nextCol]
                        board[row][nextCol] = 0
                        moved = true
                        continue
                    }
                } else if col + 1 < 4 && board[row][col] == board[row][col + 1] {
                    // 合併相同數字
                    board[row][col] *= 2
                    score += board[row][col]
                    board[row][col + 1] = 0
                    moved = true
                }
                col += 1
            }
        }
        return moved
    }
    
    private func moveRight() -> Bool {
        var moved = false
        for row in 0..<4 {
            var col = 3
            while col > 0 {
                if board[row][col] == 0 {
                    // 找到前一個非零數字
                    var prevCol = col - 1
                    while prevCol >= 0 && board[row][prevCol] == 0 {
                        prevCol -= 1
                    }
                    if prevCol >= 0 {
                        board[row][col] = board[row][prevCol]
                        board[row][prevCol] = 0
                        moved = true
                        continue
                    }
                } else if col - 1 >= 0 && board[row][col] == board[row][col - 1] {
                    // 合併相同數字
                    board[row][col] *= 2
                    score += board[row][col]
                    board[row][col - 1] = 0
                    moved = true
                }
                col -= 1
            }
        }
        return moved
    }
    
    private func moveUp() -> Bool {
        var moved = false
        for col in 0..<4 {
            var row = 0
            while row < 3 {
                if board[row][col] == 0 {
                    // 找到下一個非零數字
                    var nextRow = row + 1
                    while nextRow < 4 && board[nextRow][col] == 0 {
                        nextRow += 1
                    }
                    if nextRow < 4 {
                        board[row][col] = board[nextRow][col]
                        board[nextRow][col] = 0
                        moved = true
                        continue
                    }
                } else if row + 1 < 4 && board[row][col] == board[row + 1][col] {
                    // 合併相同數字
                    board[row][col] *= 2
                    score += board[row][col]
                    board[row + 1][col] = 0
                    moved = true
                }
                row += 1
            }
        }
        return moved
    }
    
    private func moveDown() -> Bool {
        var moved = false
        for col in 0..<4 {
            var row = 3
            while row > 0 {
                if board[row][col] == 0 {
                    // 找到前一個非零數字
                    var prevRow = row - 1
                    while prevRow >= 0 && board[prevRow][col] == 0 {
                        prevRow -= 1
                    }
                    if prevRow >= 0 {
                        board[row][col] = board[prevRow][col]
                        board[prevRow][col] = 0
                        moved = true
                        continue
                    }
                } else if row - 1 >= 0 && board[row][col] == board[row - 1][col] {
                    // 合併相同數字
                    board[row][col] *= 2
                    score += board[row][col]
                    board[row - 1][col] = 0
                    moved = true
                }
                row -= 1
            }
        }
        return moved
    }
    
    private func isGameOver() -> Bool {
        // 檢查是否還有空格
        for row in 0..<4 {
            for col in 0..<4 {
                if board[row][col] == 0 {
                    return false
                }
            }
        }
        
        // 檢查是否有可以合併的相鄰數字
        for row in 0..<4 {
            for col in 0..<4 {
                let current = board[row][col]
                
                // 檢查右邊
                if col + 1 < 4 && board[row][col + 1] == current {
                    return false
                }
                
                // 檢查下面
                if row + 1 < 4 && board[row + 1][col] == current {
                    return false
                }
            }
        }
        
        return true
    }
}
