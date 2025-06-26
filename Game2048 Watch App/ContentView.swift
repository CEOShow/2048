//
//  ContentView.swift
//  Game2048 Watch App
//
//  Created by Show on 2025/2/22.
//

import SwiftUI

struct TileMove: Equatable, Hashable {
    let from: Position
    let to: Position
    
    static func == (lhs: TileMove, rhs: TileMove) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}

struct Position: Equatable, Hashable {
    let row: Int
    let col: Int
    
    static func == (lhs: Position, rhs: Position) -> Bool {
        return lhs.row == rhs.row && lhs.col == rhs.col
    }
}

struct MovingTileModifier: ViewModifier {
    let movingTiles: [TileMove]
    let position: Position
    let tileSize: CGFloat
    let spacing: CGFloat
    @State private var offset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .onChange(of: movingTiles) { newMoves in
                if let move = newMoves.first(where: { $0.from == position }) {
                    withAnimation(.easeOut(duration: 0.1)) {  // Faster animation with simple easeOut
                        offset = CGSize(
                            width: CGFloat(move.to.col - move.from.col) * (tileSize + spacing),
                            height: CGFloat(move.to.row - move.from.row) * (tileSize + spacing)
                        )
                    }
                } else {
                    offset = .zero
                }
            }
    }
}

struct ContentView: View {
    @State private var grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var score = 0
    @State private var gameOver = false
    @State private var won = false
    @State private var hasWonBefore = false  // 新增：追蹤是否已經贏過
    @State private var movingTiles: [TileMove] = []
    @State private var isAnimating = false

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
        2048: Color(red: 0.93, green: 0.76, blue: 0.18)
    ]

    func textColor(for value: Int) -> Color {
        return value <= 4 ? Color(red: 0.47, green: 0.44, blue: 0.4) : .white
    }

    func fontSize(for value: Int) -> CGFloat {
        let digits = String(value).count
        switch digits {
        case 1: return 12
        case 2: return 10
        case 3: return 8
        default: return 6
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("分數: \(score)")
                    .font(.system(size: 10))
                    .padding(.bottom, 2)
                
                VStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { col in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colors[grid[row][col]] ?? colors[0]!)
                                        .frame(width: (geometry.size.width * 0.8) / 4, height: (geometry.size.width * 0.8) / 4)
                                    
                                    if grid[row][col] > 0 {
                                        Text("\(grid[row][col])")
                                            .font(.system(size: fontSize(for: grid[row][col]), weight: .bold))
                                            .foregroundColor(textColor(for: grid[row][col]))
                                    }
                                }
                                .modifier(MovingTileModifier(
                                    movingTiles: movingTiles,
                                    position: Position(row: row, col: col),
                                    tileSize: (geometry.size.width * 0.8) / 4,
                                    spacing: 2
                                ))
                            }
                        }
                    }
                }
                .padding(2)
                .background(Color(red: 0.73, green: 0.68, blue: 0.63))
                .cornerRadius(4)
                
                Button(action: resetGame) {
                    Text("重置")
                        .font(.system(size: 10))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(2)
                }
                .padding(.top, 2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .gesture(DragGesture(minimumDistance: 5)
                .onEnded { value in
                    if isAnimating { return }
                    
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
            .sheet(isPresented: $gameOver) {
                VStack {
                    Text("遊戲結束")
                        .font(.system(size: 14, weight: .bold))
                        .padding()
                    Text("分數: \(score)")
                        .font(.system(size: 12))
                    Button("重新開始") { resetGame() }
                        .font(.system(size: 12))
                        .padding()
                }
            }
            .sheet(isPresented: $won) {
                VStack {
                    Text("你贏了!")
                        .font(.system(size: 14, weight: .bold))
                        .padding()
                    Text("分數: \(score)")
                        .font(.system(size: 12))
                    Button("繼續") {
                        hasWonBefore = true  // 修改：設定已經贏過的標記
                        won = false
                    }
                        .font(.system(size: 12))
                        .padding()
                    Button("重玩") { resetGame() }
                        .font(.system(size: 12))
                        .padding()
                }
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
        hasWonBefore = false  // 修改：重置已贏過的標記
        movingTiles = []
        addNewTile()
        addNewTile()
    }

    func addNewTile() {
        var emptyPositions = [Position]()
        for i in 0..<4 {
            for j in 0..<4 {
                if grid[i][j] == 0 {
                    emptyPositions.append(Position(row: i, col: j))
                }
            }
        }
        
        if !emptyPositions.isEmpty {
            let randomPosition = emptyPositions.randomElement()!
            grid[randomPosition.row][randomPosition.col] = Bool.random() ? 2 : 4
        }
    }

    func checkGameStatus() {
        // 修改：只有在還沒贏過的情況下才檢查勝利條件
        if !hasWonBefore {
            for row in grid {
                if row.contains(8) {
                    won = true
                    return
                }
            }
        }
        
        for row in grid {
            if row.contains(0) { return }
        }
        
        for i in 0..<4 {
            for j in 0..<4 {
                if (j < 3 && grid[i][j] == grid[i][j + 1]) ||
                    (i < 3 && grid[i][j] == grid[i + 1][j]) {
                    return
                }
            }
        }
        gameOver = true
    }

    // Simplified move functions
    func moveRight() {
        var moved = false
        movingTiles = []
        let originalGrid = grid
        var tempGrid = grid
        
        for i in 0..<4 {
            var row = tempGrid[i].filter { $0 != 0 }
            
            // 合併相同數值的方塊
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
            
            // 建立新的一行，並填入數值
            var newRow = Array(repeating: 0, count: 4)
            let startIndex = 4 - row.count
            for (index, value) in row.enumerated() {
                newRow[startIndex + index] = value
            }
            tempGrid[i] = newRow
            
            // 計算移動路徑（如果網格有變化）
            if tempGrid[i] != originalGrid[i] {
                moved = true
                
                // 記錄原始位置的數值
                var originalValues = [(Int, Int)]() // (位置, 數值)
                for col in 0..<4 {
                    if originalGrid[i][col] != 0 {
                        originalValues.append((col, originalGrid[i][col]))
                    }
                }
                
                // 尋找每個方塊的目標位置
                for (col, value) in originalValues {
                    var found = false
                    for targetCol in (0..<4).reversed() {
                        if tempGrid[i][targetCol] == value && !found {
                            if targetCol != col {
                                movingTiles.append(TileMove(
                                    from: Position(row: i, col: col),
                                    to: Position(row: i, col: targetCol)
                                ))
                            }
                            found = true
                            tempGrid[i][targetCol] = -value // 標記為已處理，使用負值保留數值
                            break
                        }
                    }
                }
                
                // 恢復標記的負值
                for col in 0..<4 {
                    if tempGrid[i][col] < 0 {
                        tempGrid[i][col] = -tempGrid[i][col]
                    }
                }
            }
        }
        
        // 在動畫期間保持原始網格
        if moved {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.grid = tempGrid  // 動畫完成後更新網格
                self.isAnimating = false
                self.movingTiles = []
                self.addNewTile()
                self.checkGameStatus()
            }
        }
    }

    func moveLeft() {
        var moved = false
        movingTiles = []
        let originalGrid = grid
        var tempGrid = grid
        
        for i in 0..<4 {
            var row = tempGrid[i].filter { $0 != 0 }
            
            // 合併相同數值的方塊
            var j = 0
            while j < row.count - 1 {
                if row[j] == row[j+1] {
                    row[j] *= 2
                    score += row[j]
                    row.remove(at: j+1)
                }
                j += 1
            }
            
            // 建立新的一行，並填入數值
            var newRow = Array(repeating: 0, count: 4)
            for (index, value) in row.enumerated() {
                newRow[index] = value
            }
            tempGrid[i] = newRow
            
            // 計算移動路徑（如果網格有變化）
            if tempGrid[i] != originalGrid[i] {
                moved = true
                
                // 記錄原始位置的數值
                var originalValues = [(Int, Int)]() // (位置, 數值)
                for col in 0..<4 {
                    if originalGrid[i][col] != 0 {
                        originalValues.append((col, originalGrid[i][col]))
                    }
                }
                
                // 尋找每個方塊的目標位置
                for (col, value) in originalValues {
                    var found = false
                    for targetCol in 0..<4 {
                        if tempGrid[i][targetCol] == value && !found {
                            if targetCol != col {
                                movingTiles.append(TileMove(
                                    from: Position(row: i, col: col),
                                    to: Position(row: i, col: targetCol)
                                ))
                            }
                            found = true
                            tempGrid[i][targetCol] = -value // 標記為已處理，使用負值保留數值
                            break
                        }
                    }
                }
                
                // 恢復標記的負值
                for col in 0..<4 {
                    if tempGrid[i][col] < 0 {
                        tempGrid[i][col] = -tempGrid[i][col]
                    }
                }
            }
        }
        
        // 在動畫期間保持原始網格
        if moved {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.grid = tempGrid  // 動畫完成後更新網格
                self.isAnimating = false
                self.movingTiles = []
                self.addNewTile()
                self.checkGameStatus()
            }
        }
    }

    func moveUp() {
        var moved = false
        movingTiles = []
        let originalGrid = grid
        var tempGrid = grid
        
        for j in 0..<4 {
            var column = (0..<4).map { tempGrid[$0][j] }.filter { $0 != 0 }
            
            // 合併相同數值的方塊
            var i = 0
            while i < column.count - 1 {
                if column[i] == column[i+1] {
                    column[i] *= 2
                    score += column[i]
                    column.remove(at: i+1)
                }
                i += 1
            }
            
            // 建立新的一列，並填入數值
            var newColumn = Array(repeating: 0, count: 4)
            for (index, value) in column.enumerated() {
                newColumn[index] = value
            }
            for row in 0..<4 {
                tempGrid[row][j] = newColumn[row]
            }
            
            // 計算移動路徑（如果網格有變化）
            if newColumn != (0..<4).map { originalGrid[$0][j] } {
                moved = true
                
                // 記錄原始位置的數值
                var originalValues = [(Int, Int)]() // (位置, 數值)
                for row in 0..<4 {
                    if originalGrid[row][j] != 0 {
                        originalValues.append((row, originalGrid[row][j]))
                    }
                }
                
                // 尋找每個方塊的目標位置
                for (row, value) in originalValues {
                    var found = false
                    for targetRow in 0..<4 {
                        if tempGrid[targetRow][j] == value && !found {
                            if targetRow != row {
                                movingTiles.append(TileMove(
                                    from: Position(row: row, col: j),
                                    to: Position(row: targetRow, col: j)
                                ))
                            }
                            found = true
                            tempGrid[targetRow][j] = -value // 標記為已處理，使用負值保留數值
                            break
                        }
                    }
                }
                
                // 恢復標記的負值
                for row in 0..<4 {
                    if tempGrid[row][j] < 0 {
                        tempGrid[row][j] = -tempGrid[row][j]
                    }
                }
            }
        }
        
        // 在動畫期間保持原始網格
        if moved {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.grid = tempGrid  // 動畫完成後更新網格
                self.isAnimating = false
                self.movingTiles = []
                self.addNewTile()
                self.checkGameStatus()
            }
        }
    }

    func moveDown() {
        var moved = false
        movingTiles = []
        let originalGrid = grid
        var tempGrid = grid
        
        for j in 0..<4 {
            var column = (0..<4).map { tempGrid[$0][j] }.filter { $0 != 0 }
            
            // 合併相同數值的方塊
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
            
            // 建立新的一列，並填入數值
            var newColumn = Array(repeating: 0, count: 4)
            let startIndex = 4 - column.count
            for (index, value) in column.enumerated() {
                newColumn[startIndex + index] = value
            }
            for row in 0..<4 {
                tempGrid[row][j] = newColumn[row]
            }
            
            // 計算移動路徑（如果網格有變化）
            if newColumn != (0..<4).map { originalGrid[$0][j] } {
                moved = true
                
                // 記錄原始位置的數值
                var originalValues = [(Int, Int)]() // (位置, 數值)
                for row in 0..<4 {
                    if originalGrid[row][j] != 0 {
                        originalValues.append((row, originalGrid[row][j]))
                    }
                }
                
                // 尋找每個方塊的目標位置
                for (row, value) in originalValues {
                    var found = false
                    for targetRow in (0..<4).reversed() {
                        if tempGrid[targetRow][j] == value && !found {
                            if targetRow != row {
                                movingTiles.append(TileMove(
                                    from: Position(row: row, col: j),
                                    to: Position(row: targetRow, col: j)
                                ))
                            }
                            found = true
                            tempGrid[targetRow][j] = -value // 標記為已處理，使用負值保留數值
                            break
                        }
                    }
                }
                
                // 恢復標記的負值
                for row in 0..<4 {
                    if tempGrid[row][j] < 0 {
                        tempGrid[row][j] = -tempGrid[row][j]
                    }
                }
            }
        }
        
        // 在動畫期間保持原始網格
        if moved {
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.grid = tempGrid  // 動畫完成後更新網格
                self.isAnimating = false
                self.movingTiles = []
                self.addNewTile()
                self.checkGameStatus()
            }
        }
    }
}

// 預覽（僅限 Xcode 使用）
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("Apple Watch Series 8 - 45mm")
    }
}
