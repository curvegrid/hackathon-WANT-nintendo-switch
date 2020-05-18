<template>
  <div class="home">
    <img
      alt="Woman with Ethereum Balloons"
      src="../assets/logo.png"
    >
    <HelloWorld msg="Welcome to Your Vue.js DApp" />
  </div>
</template>

<script>
// @ is an alias to /src
import HelloWorld from '../components/HelloWorld.vue';

export default {
  name: 'Home',
  components: {
    HelloWorld,
  },
};
</script>
