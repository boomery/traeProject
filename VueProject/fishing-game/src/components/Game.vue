<template>
  <div class="game-container">
    <div class="game-area" @mousemove="handleMouseMove" @click="shoot">
      <div v-for="fish in fishes" :key="fish.id" 
           class="fish" 
           :style="getFishStyle(fish)">
        <div class="fish-body"></div>
      </div>
      <div v-for="bullet in bullets" :key="bullet.id" 
           class="bullet" 
           :style="getBulletStyle(bullet)">
      </div>
      <div class="cannon" :style="getCannonStyle()">
        <div class="cannon-body"></div>
      </div>
      <div v-if="isGameRunning" class="game-info">
        <div>炮台等级: {{ cannonLevel }}</div>
        <div>游戏时间: {{ gameTime }}秒</div>
      </div>
    </div>
    <div class="game-controls">
      <div class="game-status">
        <div>分数: {{ score }}</div>
        <div>金币: {{ coins }}</div>
      </div>
      <div class="game-buttons">
        <button @click="startGame" :disabled="isGameRunning">开始游戏</button>
        <button @click="pauseGame" :disabled="!isGameRunning">暂停游戏</button>
        <button @click="upgradeCannon" :disabled="coins < 100">升级炮台 (100金币)</button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FishingGame',
  data() {
    return {
      score: 0,
      coins: 0,
      cannonLevel: 1,
      isGameRunning: false,
      gameTimer: null,
      gameTime: 0,
      gameInterval: null,
      // 游戏对象
      fishes: [],
      bullets: [],
      nextFishId: 1,
      nextBulletId: 1,
      // 炮台位置
      cannonX: 400,
      cannonY: 550,
      cannonAngle: 0,
      // 游戏配置
      fishTypes: [
        { speed: 2, size: 30, score: 10, coins: 5, color: '#FF6B6B' },
        { speed: 3, size: 40, score: 20, coins: 10, color: '#4ECDC4' },
        { speed: 4, size: 50, score: 30, coins: 15, color: '#45B7D1' }
      ]
    }
  },
  methods: {
    handleMouseMove(event) {
      if (!this.isGameRunning) return
      const rect = event.target.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top
      this.cannonAngle = Math.atan2(y - this.cannonY, x - this.cannonX)
    },
    shoot() {
      if (!this.isGameRunning) return
      const bullet = {
        id: this.nextBulletId++,
        x: this.cannonX,
        y: this.cannonY,
        angle: this.cannonAngle,
        speed: 10 + this.cannonLevel
      }
      this.bullets.push(bullet)
    },
    getFishStyle(fish) {
      return {
        left: `${fish.x}px`,
        top: `${fish.y}px`,
        transform: `rotate(${fish.angle}rad)`,
        width: `${fish.size}px`,
        height: `${fish.size}px`
      }
    },
    getBulletStyle(bullet) {
      return {
        left: `${bullet.x}px`,
        top: `${bullet.y}px`,
        transform: `rotate(${bullet.angle}rad)`
      }
    },
    getCannonStyle() {
      return {
        left: `${this.cannonX}px`,
        top: `${this.cannonY}px`,
        transform: `rotate(${this.cannonAngle}rad)`
      }
    },
    createFish() {
      const type = this.fishTypes[Math.floor(Math.random() * this.fishTypes.length)]
      const fish = {
        id: this.nextFishId++,
        x: -50,
        y: Math.random() * 500 + 50,
        angle: Math.atan2(0, 1),
        speed: type.speed,
        size: type.size,
        score: type.score,
        coins: type.coins,
        color: type.color
      }
      this.fishes.push(fish)
    },
    updateGame() {
      // 更新鱼的位置
      this.fishes.forEach(fish => {
        fish.x += fish.speed
        // 如果鱼游出屏幕，移除它
        if (fish.x > 850) {
          this.fishes = this.fishes.filter(f => f.id !== fish.id)
        }
      })

      // 更新子弹位置
      this.bullets.forEach(bullet => {
        bullet.x += Math.cos(bullet.angle) * bullet.speed
        bullet.y += Math.sin(bullet.angle) * bullet.speed

        // 检查子弹是否击中鱼
        this.fishes.forEach(fish => {
          const dx = bullet.x - (fish.x + fish.size / 2)
          const dy = bullet.y - (fish.y + fish.size / 2)
          const distance = Math.sqrt(dx * dx + dy * dy)

          if (distance < fish.size / 2) {
            // 击中鱼
            this.score += fish.score * this.cannonLevel
            this.coins += fish.coins * this.cannonLevel
            this.fishes = this.fishes.filter(f => f.id !== fish.id)
            this.bullets = this.bullets.filter(b => b.id !== bullet.id)
          }
        })

        // 移除超出屏幕的子弹
        if (bullet.x < 0 || bullet.x > 800 || bullet.y < 0 || bullet.y > 600) {
          this.bullets = this.bullets.filter(b => b.id !== bullet.id)
        }
      })
    },
    upgradeCannon() {
      if (this.coins >= 100) {
        this.coins -= 100
        this.cannonLevel++
      }
    },
    startGame() {
      this.isGameRunning = true
      this.gameTime = 0
      this.score = 0
      this.coins = 0
      this.fishes = []
      this.bullets = []
      this.nextFishId = 1
      this.nextBulletId = 1
      
      // 开始计时
      this.gameTimer = setInterval(() => {
        this.gameTime++
      }, 1000)
      
      // 游戏主循环
      this.gameInterval = setInterval(() => {
        this.updateGame()
        // 随机生成鱼
        if (Math.random() < 0.02) {
          this.createFish()
        }
      }, 1000 / 60) // 60 FPS
    },
    pauseGame() {
      this.isGameRunning = false
      if (this.gameTimer) {
        clearInterval(this.gameTimer)
        this.gameTimer = null
      }
      if (this.gameInterval) {
        clearInterval(this.gameInterval)
        this.gameInterval = null
      }
    }
  },
  beforeDestroy() {
    this.pauseGame()
  }
}
</script>

<style scoped>
.game-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
}

.game-area {
  width: 800px;
  height: 600px;
  border: 2px solid #333;
  margin-bottom: 20px;
  position: relative;
  background: #1a1a1a;
  overflow: hidden;
  cursor: crosshair;
}

.fish {
  position: absolute;
  transform-origin: center;
}

.fish-body {
  width: 100%;
  height: 100%;
  background: currentColor;
  border-radius: 50%;
  position: relative;
}

.fish-body::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  width: 30%;
  height: 30%;
  background: white;
  border-radius: 50%;
  transform: translate(-50%, -50%);
}

.bullet {
  position: absolute;
  width: 8px;
  height: 8px;
  background: #FFD700;
  border-radius: 50%;
  transform-origin: center;
}

.cannon {
  position: absolute;
  width: 40px;
  height: 40px;
  transform-origin: center;
}

.cannon-body {
  width: 100%;
  height: 100%;
  background: #4CAF50;
  border-radius: 50%;
  position: relative;
}

.cannon-body::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 60px;
  height: 10px;
  background: #4CAF50;
  transform: translate(-50%, -50%) rotate(90deg);
  transform-origin: left center;
}

.game-info {
  position: absolute;
  top: 20px;
  left: 20px;
  font-size: 18px;
  text-align: left;
  color: white;
  background: rgba(0, 0, 0, 0.5);
  padding: 10px;
  border-radius: 8px;
}

.game-controls {
  width: 800px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background: #f5f5f5;
  border-radius: 8px;
}

.game-status {
  font-size: 18px;
  font-weight: bold;
}

.game-buttons {
  display: flex;
  gap: 10px;
}

button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  background: #4CAF50;
  color: white;
  cursor: pointer;
  font-size: 16px;
}

button:disabled {
  background: #cccccc;
  cursor: not-allowed;
}

button:hover:not(:disabled) {
  background: #45a049;
}
</style> 