<template>
  <v-container>
    <v-row class="text-center">
      <v-col cols="12">
        <v-img
          :src="require('../assets/logo.svg')"
          class="my-3"
          contain
          height="200"
        />
      </v-col>

      <v-col
        class="mb-4"
        cols="12"
      >
        <v-tabs
          v-model="tab"
          background-color="primary lighten-1"
          icons-and-text
          centered
          grow
        >
          <v-tab>
            Deposit
            <v-icon>account-balance</v-icon>
          </v-tab>
          <v-tab>
            Redeem
            <v-icon>local-play</v-icon>
          </v-tab>
        </v-tabs>

        <v-tabs-items v-model="tab">
          <v-tab-item
            :key="0"
          >
            <v-card
              flat
            >
              <deposit />
            </v-card>
          </v-tab-item>
          <v-tab-item
            :key="1"
          >
            <v-card
              flat
            >
              <redeem />
            </v-card>
          </v-tab-item>
        </v-tabs-items>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import Deposit from '../components/Deposit.vue';
import Redeem from '../components/Redeem.vue';


export default {
  name: 'Home',
  components: {
    Deposit,
    Redeem,
  },
  data: () => ({
    tab: 0,
    tokenName: '',
    tokenSupply: 0,
    contract: 'want',
    address: 'want8',
    sender: '0xBaC1Cd4051c378bF900087CCc445d7e7d02ad745',
    apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1OTAwMjM2NjcsInN1YiI6IjEifQ.dOD6AydCrB0yLuN8A3wnpJlWBpd7L8XVwiZGoAV0jzU',
  }),
  created() {
    this.getTokenSupply();
    this.getTokenName();
    console.log(this.tokenName);

    bus.$on('deposit', (address, amount) => this.deposit(address, amount));
  },
  methods: {
    async getTokenSupply() {
      this.tokenSupply = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'NumberOfTokens', this.sender,
        this.apiKey);
    },
    async getTokenName() {
      this.tokenName = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'name', this.sender,
        this.apiKey);
    },
    async deposit(address, amount) {
      const args = [`${address}`, `${amount}`];
      // TODO: need to make the sender the user's active metamast account
      await this.$root.$_cgutils.sendMethod(this.address, this.contract, 'deposit', this.sender, this.$root.$_web3,
        this.apiKey, args);
    },
  },
};
</script>
