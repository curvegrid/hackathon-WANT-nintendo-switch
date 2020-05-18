<template>
  <v-app>
    <v-app-bar
      app
      color="primary"
      dark
    >
      <div class="d-flex align-center">
        <v-toolbar-title>
          Token Pool Exchange
        </v-toolbar-title>
      </div>
    </v-app-bar>
    <v-content>
      <HelloWorld />
    </v-content>
  </v-app>
</template>

<script>
import { ethers } from 'ethers';
import HelloWorld from './components/HelloWorld.vue';

export default {
  name: 'App',
  components: {
    HelloWorld,
  },
  data: () => ({
  }),
  async beforeMount() {
    await this.connectToWeb3();
  },
  methods: {
    connectToWeb3() {
      this.$root.$_web3Available = false;
      if (typeof window.web3 !== 'undefined') {
        // Use MetaMask's provider
        this.$root.$_web3 = new ethers.providers.Web3Provider(window.web3.currentProvider);
        this.$root.$_web3Available = true;
      } else {
        const fallbackWeb3 = '/web3';
        console.warn(`No web3 detected. Falling back to ${fallbackWeb3}. Connecting using ethers.js.`);

        // fallback - use your fallback strategy
        // (local node / hosted node + in-dapp id mgmt / fail)
        this.$root.$_web3 = new ethers.providers.JsonRpcProvider(fallbackWeb3);
      }
    },
  },
};
</script>
