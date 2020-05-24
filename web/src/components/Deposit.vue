<template>
  <v-container>
    <v-form
      @submit.prevent
    >
      <v-row align="center">
        <v-col
          class="d-flex"
          cols="12"
          sm="6"
        >
          <v-select
            v-model="selectedToken"
            :items="tokenNames"
            label="Token"
            :disabled="transactionStatus !== null"
            @change="updateToken"
          />
        </v-col>
        <v-col
          class="d-flex"
          cols="12"
          sm="6"
        >
          <v-text-field
            v-model="amount"
            label="Amount"
            :rules="[validAmount]"
            :disabled="transactionStatus !== null"
          >
            <template
              v-if="tokenBalance != null"
              v-slot:append
            >
              You have {{ tokenBalance }} {{ selectedToken }}
            </template>
          </v-text-field>
        </v-col>
      </v-row>
      <v-row
        v-if="tokenAllowance !== null"
        class="text-center"
      >
        <v-col>
          <v-btn
            v-if="!needsApproval && transactionStatus === null"
            color="primary"
            :disabled="!fieldsCompleted"
            @click="deposit()"
          >
            Deposit and Get
            {{ payout === null ? '???' : payout }} WANT token!
          </v-btn>
          <v-btn
            v-if="needsApproval && transactionStatus === null"
            color="primary"
            :disabled="!fieldsCompleted"
            @click="approve()"
          >
            Approve {{ amount }} {{ selectedToken }} to Get
            {{ payout === null ? '???' : payout }} WANT token!
          </v-btn>
          <v-btn
            v-if="transactionStatus !== null"
            color="primary"
            disabled
          >
            {{ transactionStatus }}
          </v-btn>
        </v-col>
      </v-row>
    </v-form>
  </v-container>
</template>

<script>

// https://levelup.gitconnected.com/debounce-in-javascript-improve-your-applications-performance-5b01855e086
// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
  let timeout;

  return function executedFunction(...args) {
    const context = this;

    const later = () => {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };

    const callNow = immediate && !timeout;

    clearTimeout(timeout);

    timeout = setTimeout(later, wait);

    if (callNow) func.apply(context, args);
  };
}

export default {
  props: {
    sender: {
      type: String,
      required: true,
    },
    apiKey: {
      type: String,
      required: true,
    },
    wantAddress: {
      type: String,
      required: true,
    },
    contract: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      amount: 0,
      transactionStatus: null,
      selectedToken: null,
      tokenDecimals: null,
      tokenAllowance: null,
      tokenBalance: null,
      payout: null,
      acceptedTokens: {
        ZRX: '0xddea378A6dDC8AfeC82C36E9b0078826bf9e68B6',
        WBTC: '0x577D296678535e4903D59A4C929B718e1D575e0A',
        USDC: '0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b',
        DAI: '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa',
      },
    };
  },
  computed: {
    tokenNames() {
      return Object.keys(this.acceptedTokens);
    },
    fieldsCompleted() {
      return this.selectedToken != null && this.tokenDecimals != null
        && this.tokenAllowance != null && this.tokenBalance != null && this.amount > 0
        && this.validAmount === true;
    },
    validAmount() {
      if (this.tokenBalance === null) { return 'Loading balance...'; }
      return this.amount <= Number(this.tokenBalance) ? true : 'Insufficient balance';
    },
    needsApproval() {
      return this.amount > Number(this.tokenAllowance);
    },
    amountWithDecimals() {
      if (this.tokenDecimals === null) return null;
      return this.amount * (10 ** this.tokenDecimals);
    },
  },
  watch: {
    amount() {
      if (this.validAmount === true) { this.debouncedUpdatePayout(); }
    },
  },
  created() {
    const up = debounce(() => this.updatePayout(), 500);
    this.debouncedUpdatePayout = () => {
      this.payout = null;
      up();
    };
  },
  methods: {
    async approve() {
      const tokenAddr = this.acceptedTokens[this.selectedToken];
      await this.call(tokenAddr, 'erc20d', 'approve', this.wantAddress, this.amount);
      this.updateToken();
    },
    async deposit() {
      const tokenAddr = this.acceptedTokens[this.selectedToken];
      await this.call(this.wantAddress, this.contract, 'deposit', tokenAddr, this.amountWithDecimals);
      this.updateToken();
      bus.$emit('update');
    },
    async call(addr, contract, method, ...inArgs) {
      const args = inArgs.map((v) => `${v}`);
      this.transactionStatus = 'Transaction in Progress...';
      // TODO: need to make the sender the user's active metamask account
      await this.$root.$_cgutils.sendMethod(
        addr, contract, method, this.sender, this.$root.$_web3,
        this.apiKey, args, { contractOverride: true },
      );
      this.transactionStatus = null;
    },
    async updatePayout() {
      this.payout = null;
      this.payout = await this.$root.$_cgutils.callMethod(this.wantAddress, this.contract, 'getPayout', this.sender, this.apiKey, [this.acceptedTokens[this.selectedToken], this.amountWithDecimals]);
    },
    async updateToken() {
      this.tokenDecimals = null;
      this.tokenAllowance = null;
      this.tokenBalance = null;
      const [decimals, allowance, balance] = await Promise.all([
        this.$root.$_cgutils.callMethod(this.acceptedTokens[this.selectedToken], 'erc20d', 'decimals', this.sender, this.apiKey, [], {
          contractOverride: true,
        }),
        this.$root.$_cgutils.callMethod(this.acceptedTokens[this.selectedToken], 'erc20d', 'allowance', this.sender, this.apiKey, [this.sender, this.wantAddress], {
          contractOverride: true,
        }),
        this.$root.$_cgutils.callMethod(this.acceptedTokens[this.selectedToken], 'erc20d', 'balanceOf', this.sender, this.apiKey, [this.sender], {
          contractOverride: true,
        }),
      ]);
      this.tokenDecimals = Number(decimals);
      this.tokenAllowance = allowance;
      this.tokenBalance = balance;
      await this.updatePayout();
    },
  },
};

</script>
