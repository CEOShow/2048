//
//  ContentView.swift
//  Game2048 Watch App
//
//  Created by Show on 2025/2/22.
//

import SwiftUI

struct ContentView: View {
    @State private var grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var score = 0
    @State private var gameOver = false
    @State private var won = false
    
    // 官方 2048 配色（增加4096和8192的顏色）
        let colors: [Int: Color] = [
            0: Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.35),
            2: Color(red: 0.93, green: 0.89, blue: 0.85),
            4: Color(red: 0.93, green: 0.88, blue: 0.78),
            8: Color(red: 0.95, green: 0.69, blue: 0.47),
            16: Color(red: 0.96, green: 0.58, blue: 0.39),
            32: Color(red: 0.96, green: 0.49, blue: 0.37),
            64: Color(red: 0.96, green: 0.37, blue: 0.24),
            128: Color(red: 0.93, green: 0.81, blue: 0.45),
            256: Color(red: 0.93, green: 0.8, blue: 0.38),
            512: Color(red: 0.93, green: 0.78, blue: 0.31),
            1024: Color(red: 0.93, green: 0.77, blue: 0.25),
            2048: Color(red: 0.93, green: 0.76, blue: 0.18),
            4096: Color(red: 0.77, green: 0.82, blue: 0.28), // 黃綠色，橙黃到綠色的過渡
            8192: Color(red: 0.62, green: 0.87, blue: 0.38) // 鮮綠色，對比於橙黃色系列
    ]
    
    // 文字顏色
    func textColor(for value: Int) -> Color {
        return value <= 4 ? Color(red: 0.47, green: 0.44, blue: 0.4) : .white
    }
    
    // 文字大小
    func fontSize(for value: Int) -> CGFloat {
        let digits = String(value).count
        if digits <= 1 {
            return 14
        } else if digits == 2 {
            return 12
        } else if digits == 3 {
            return 9
        } else {
            return 7
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("分數: \(score)")
                    .font(.system(size: 12))
                    .padding(.bottom, 2)
                
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { col in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colors[grid[row][col]] ?? colors[0]!)
                                        .frame(width: (geometry.size.width * 0.8) / 4, height: (geometry.size.width * 0.8) / 4)
                                    
                                    if grid[row][col] > 0 {
                                        Text("\(grid[row][col])")
                                            .font(.system(size: fontSize(for: grid[row][col]), weight: .bold))
                                            .foregroundColor(textColor(for: grid[row][col]))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(2)
                .background(Color(red: 0.73, green: 0.68, blue: 0.63))
                .cornerRadius(5)
                
                HStack {
                    Button(action: resetGame) {
                        Text("重置")
                            .font(.system(size: 12))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                    }
                }
                .padding(.top, 3)
            }
            .sheet(isPresented: $gameOver) {
                VStack {
                    Text("遊戲結束")
                        .font(.title2)
                        .bold()
                        .padding()
                    Text("你的分數: \(score)")
                    Button("重新開始") {
                        resetGame()
                    }
                    .padding()
                }
            }

            .sheet(isPresented: $won) {
                VStack {
                    Text("你贏了!")
                        .font(.title2)
                        .bold()
                        .padding()
                    Text("你的分數: \(score)")
                    Button("繼續遊戲") {
                        won = false
                    }
                    .padding()
                    Button("重新開始") {
                        resetGame()
                    }
                    .padding()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 {
                            moveLeft()
                        } else {
                            moveRight()
                        }
                    } else {
                        if verticalAmount < 0 {
                            moveUp()
                        } else {
                            moveDown()
                        }
                    }
                }
            )
            .alert(isPresented: $gameOver) {
                Alert(
                    title: Text("遊戲結束"),
                    message: Text("你的分數: \(score)"),
                    dismissButton: .default(Text("重新開始")) {
                        resetGame()
                    }
                )
            }
            .alert(isPresented: $won) {
                Alert(
                    title: Text("你贏了!"),
                    message: Text("你的分數: \(score)"),
                    primaryButton: .default(Text("繼續遊戲")) {
                        won = false
                    },
                    secondaryButton: .default(Text("重新開始")) {
                        resetGame()
                    }
                )
            }
            .onAppear(perform: startGame)
        }
    }
    
    func startGame() {
        resetGame()
    }
    
    func resetGame() {
        grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        gameOver = false
        won = false
        addNewTile()
        addNewTile()
    }
    
    func addNewTile() {
        var emptyPositions = [(Int, Int)]()
        
        for i in 0..<4 {
            for j in 0..<4 {
                if grid[i][j] == 0 {
                    emptyPositions.append((i, j))
                }
            }
        }
        
        if !emptyPositions.isEmpty {
            let randomPosition = emptyPositions.randomElement()!
            grid[randomPosition.0][randomPosition.1] = Bool.random() ? 2 : 4
        }
    }
    
    func checkGameStatus() {
        print("檢查遊戲狀態開始")

        // 檢查是否獲勝
        for row in grid {
            for value in row {
                if value == 2048 {
                    print("遊戲勝利")
                    won = true
                    return
                }
            }
        }
        
        // 檢查是否有空格，若有則遊戲尚未結束
        for row in grid {
            if row.contains(0) {
                print("尚有空格，遊戲繼續")
                return
            }
        }
        
        // 檢查是否還能合併（左右與上下）
        for i in 0..<4 {
            for j in 0..<4 {
                if (j < 3 && grid[i][j] == grid[i][j + 1]) || // 檢查左右
                   (i < 3 && grid[i][j] == grid[i + 1][j]) { // 檢查上下
                    print("還可以合併，遊戲繼續")
                    return
                }
            }
        }
        
        // 如果沒有空格，且無法合併，則遊戲結束
        print("遊戲結束")
        gameOver = true
    }
    
    func moveLeft() {
        var moved = false
        for i in 0..<4 {
            var row = grid[i]
            let originalRow = row
            
            // 移除零
            row = row.filter { $0 != 0 }
            
            // 合併相同的數字
            var j = 0
            while j < row.count - 1 {
                if row[j] == row[j+1] {
                    row[j] *= 2
                    score += row[j]
                    row.remove(at: j+1)
                }
                j += 1
            }
            
            // 填充零
            while row.count < 4 {
                row.append(0)
            }
            
            if originalRow != row {
                moved = true
            }
            
            grid[i] = row
        }
        
        if moved {
            addNewTile()
            checkGameStatus()
        }
    }
    
    func moveRight() {
        var moved = false
        for i in 0..<4 {
            var row = grid[i]
            let originalRow = row
            
            // 移除零
            row = row.filter { $0 != 0 }
            
            // 合併相同的數字 (從右向左)
            var j = row.count - 1
            while j > 0 {
                if row[j] == row[j-1] {
                    row[j] *= 2
                    score += row[j]
                    row.remove(at: j-1)
                    j -= 1
                }
                j -= 1
            }
            
            // 填充零
            while row.count < 4 {
                row.insert(0, at: 0)
            }
            
            if originalRow != row {
                moved = true
            }
            
            grid[i] = row
        }
        
        if moved {
            addNewTile()
            checkGameStatus()
        }
    }
    
    func moveUp() {
        var moved = false
        for j in 0..<4 {
            var column = [grid[0][j], grid[1][j], grid[2][j], grid[3][j]]
            let originalColumn = column
            
            // 移除零
            column = column.filter { $0 != 0 }
            
            // 合併相同的數字
            var i = 0
            while i < column.count - 1 {
                if column[i] == column[i+1] {
                    column[i] *= 2
                    score += column[i]
                    column.remove(at: i+1)
                }
                i += 1
            }
            
            // 填充零
            while column.count < 4 {
                column.append(0)
            }
            
            if originalColumn != column {
                moved = true
            }
            
            grid[0][j] = column[0]
            grid[1][j] = column[1]
            grid[2][j] = column[2]
            grid[3][j] = column[3]
        }
        
        if moved {
            addNewTile()
            checkGameStatus()
        }
    }
    
    func moveDown() {
        var moved = false
        for j in 0..<4 {
            var column = [grid[0][j], grid[1][j], grid[2][j], grid[3][j]]
            let originalColumn = column
            
            // 移除零
            column = column.filter { $0 != 0 }
            
            // 合併相同的數字 (從下向上)
            var i = column.count - 1
            while i > 0 {
                if column[i] == column[i-1] {
                    column[i] *= 2
                    score += column[i]
                    column.remove(at: i-1)
                    i -= 1
                }
                i -= 1
            }
            
            // 填充零
            while column.count < 4 {
                column.insert(0, at: 0)
            }
            
            if originalColumn != column {
                moved = true
            }
            
            grid[0][j] = column[0]
            grid[1][j] = column[1]
            grid[2][j] = column[2]
            grid[3][j] = column[3]
        }
        
        if moved {
            addNewTile()
            checkGameStatus()
        }
    }
}
