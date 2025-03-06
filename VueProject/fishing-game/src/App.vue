<template>
  <div id="app">
    <h1>捕鱼达人</h1>
    <Game />
  </div>
</template>

<script>
import Game from './components/Game.vue'

export default {
  name: 'App',
  components: {
    Game
  }
}
</script>

<style>
#app {
  font-family: Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

h1 {
  color: #2196F3;
  margin-bottom: 30px;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
</style>
