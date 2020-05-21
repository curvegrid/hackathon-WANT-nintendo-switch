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
      // TODO: populate this list of tokens our platform accepts and the correct addresses
      acceptedTokens: {
        DAI: '0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658',
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
