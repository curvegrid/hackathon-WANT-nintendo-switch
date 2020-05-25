<template>
  <div>
    <v-banner
      tile
      color="primary lighten-4"
      fluid
      icon="account_balance"
    >
      <div>Your WANT Balance: {{ wantBalance }}</div>
      <v-spacer />
      <div>Number of Tokens in the Pool: {{ poolTokenCount }}</div>
      <v-spacer />
      <div v-if="claimCost">
        Your next claim will cost {{ claimCost }} WANT tokens
      </div>
    </v-banner>
    <tokens-view
      :tokens="tokens"
      :total-tokens="Number(poolTokenCount)"
    />
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
      </v-row>
      <v-card fluid>
        <v-row class="text-center">
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
                  <deposit
                    v-if="hexAddress != null"
                    :contract="contract"
                    :sender="sender"
                    :want-address="hexAddress"
                    :api-key="apiKey"
                    :accepted-tokens="tokenAddresses"
                  />
                </v-card>
              </v-tab-item>
              <v-tab-item
                :key="1"
              >
                <v-card
                  flat
                >
                  <redeem
                    :claim-cost="Number(claimCost)"
                    :tokens="tokens"
                    :balance="Number(wantBalance)"
                    :redeem="redeem"
                    :get-events-from-tx-hash="getEventsFromTxHash"
                  />
                </v-card>
              </v-tab-item>
            </v-tabs-items>
          </v-col>
        </v-row>
      </v-card>

      <v-row>
        <v-col cols="12">
          <v-alert
            v-model="showMessage"
            dismissible
            class="text-center headline"
            type="success"
          >
            {{ message }}
          </v-alert>
        </v-col>
      </v-row>
    </v-container>
  </div>
</template>

<script>
import Deposit from '../components/Deposit.vue';
import Redeem from '../components/Redeem.vue';
import TokensView from '../components/Tokens.vue';

export default {
  name: 'Home',
  components: {
    Deposit,
    Redeem,
    TokensView,
  },
  data: () => ({
    tab: 0,
    tokenName: '',
    wantBalance: 0,
    poolTokenCount: 0,
    claimCost: null,
    sender: null,

    tokenAddresses: {
      ZRX: '0xddea378A6dDC8AfeC82C36E9b0078826bf9e68B6',
      WBTC: '0x577D296678535e4903D59A4C929B718e1D575e0A',
      USDC: '0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b',
      DAI: '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa',
    },
    tokens: [],

    contract: 'want',
    address: 'want_demo_v0',
    hexAddress: null,
    apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1OTAwMjM2NjcsInN1YiI6IjEifQ.dOD6AydCrB0yLuN8A3wnpJlWBpd7L8XVwiZGoAV0jzU',

    showMessage: false,
    message: '',
  }),
  watch: {
    tab() {
    },
  },
  created() {
    const getSender = () => {
      if (window.ethereum.selectedAddress) {
        this.sender = window.ethereum.selectedAddress;
        this.updateBalances();
        this.getHexAddress();
        return;
      }
      setTimeout(getSender, 500);
    };
    getSender();

    bus.$on('update', () => this.updateBalances());
    bus.$on('message', (message) => {
      this.showMessage = true;
      this.message = message;
    });
    bus.$on('hide-message', () => { this.showMessage = false; });
  },
  methods: {
    async updateBalances() {
      this.getWantBalance();
      this.getPoolBalance();
      this.getClaimCost();
      this.updateTokens();
    },
    async getHexAddress() {
      const res = await this.$root.$_cgutils.get(`/api/v0/chains/ethereum/addresses/${this.address}`, this.apiKey);
      this.hexAddress = res.data.result.address;
    },
    async getWantBalance() {
      const args = [`${this.sender}`];
      this.wantBalance = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'balanceOf', this.sender,
        this.apiKey, args);
    },
    async getPoolBalance() {
      this.poolTokenCount = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'totalOwnedTokens', this.sender,
        this.apiKey);
    },
    async getClaimCost() {
      this.claimCost = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'claimCost', this.sender,
        this.apiKey);
    },
    async getTokenName() {
      this.tokenName = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'name', this.sender,
        this.apiKey);
    },
    async redeem() {
      const args = [1];
      return this.$root.$_cgutils.sendMethod(this.address, this.contract, 'claim', this.sender, this.$root.$_web3,
        this.apiKey, args);
    },
    async getEventsFromTxHash(hash, name) {
      const res = await this.$root.$_cgutils.get(`/api/v0/chains/ethereum/addresses/${this.address}/events?tx_hash=${hash}&name=${name}`, this.apiKey);
      return res.data.result;
    },

    async updateTokens() {
      const tokens = await Promise.all(Object.keys(this.tokenAddresses).map(async (tokenName) => {
        const address = this.tokenAddresses[tokenName];
        return { name: tokenName, address, amount: await this.getTokenBalance(address) };
      }));
      tokens.sort((a, b) => a.amount - b.amount);
      this.tokens = tokens;
    },
    getTokenBalance(address) {
      return this.$root.$_cgutils.callMethod(this.address, this.contract, 'ownedTokenAmount', this.sender,
        this.apiKey, [address]);
    },
  },
};
</script>
