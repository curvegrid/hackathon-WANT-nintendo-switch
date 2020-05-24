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
    </v-banner>
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
                    :success-message="redeemStatus.successMessage"
                    :error-message="redeemStatus.errorMessage"
                  />
                </v-card>
              </v-tab-item>
            </v-tabs-items>
          </v-col>
        </v-row>
      </v-card>
    </v-container>
  </div>
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
    wantBalance: 0,
    poolTokenCount: 0,

    redeemStatus: {
      successMessage: '',
      errorMessage: '',
    },
    contract: 'want',
    address: 'want_demo_v0',
    hexAddress: null,
    apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1OTAwMjM2NjcsInN1YiI6IjEifQ.dOD6AydCrB0yLuN8A3wnpJlWBpd7L8XVwiZGoAV0jzU',
  }),
  computed: {
    sender() {
      return window.ethereum.selectedAddress;
    },
  },
  watch: {
    tab() {
      console.log('tab change');
      this.$set(this.redeemStatus, 'successMessage', '');
      this.$set(this.redeemStatus, 'errorMessage', '');
    },
  },
  created() {
    this.updateBalances();
    this.getHexAddress();

    bus.$on('update', () => this.updateBalances());
    bus.$on('redeem', (amount) => this.redeem(amount));
  },
  methods: {
    async updateBalances() {
      this.getWantBalance();
      this.getPoolBalance();
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
    async getTokenName() {
      this.tokenName = await this.$root.$_cgutils.callMethod(this.address, this.contract, 'name', this.sender,
        this.apiKey);
    },
    async redeem(amount) {
      const args = [`${amount}`];
      await this.$root.$_cgutils.sendMethod(this.address, this.contract, 'claim', this.sender, this.$root.$_web3,
        this.apiKey, args);
      // TODO make this meaningful
      this.redeemStatus.successMessage = 'Congrats you earned 1 MANA!';
    },
  },
};
</script>
