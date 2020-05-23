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
          />
        </v-col>
      </v-row>
      <v-row class="text-center">
        <v-col>
          <v-btn
            color="primary"
            :disabled="!fieldsCompleted"
            @click="deposit()"
          >
            Deposit
          </v-btn>
        </v-col>
      </v-row>
    </v-form>
  </v-container>
</template>

<script>
export default {
  data() {
    return {
      amount: 0,
      selectedToken: null,
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
      return this.selectedToken != null && this.amount > 0;
    },

  },
  methods: {
    deposit() {
      if (this.fieldsCompleted) {
        const tokenAddr = this.acceptedTokens[this.selectedToken];
        bus.$emit('deposit', tokenAddr, this.amount);
      }
    },
  },
};
</script>
