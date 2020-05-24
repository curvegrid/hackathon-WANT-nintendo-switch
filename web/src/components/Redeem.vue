<template>
  <div>
    <v-container>
      <v-form
        @submit.prevent
      >
        <v-row class="text-center headline">
          <v-col>
            <v-btn
              v-if="sufficientBalance"
              color="primary"
              x-large
              :loading="loading"
              @click="doRedeem()"
            >
              Redeem {{ claimCost }} WANT tokens to get ONE {{ tokens[random].name }}?!
            </v-btn>
            <div v-if="!sufficientBalance">
              You have insufficient balance (<b>{{ balance }}</b> out of <b>{{ claimCost }}</b>
              WANT tokens) to claim one {{ tokens[random].name }}... Deposit more?
            </div>
          </v-col>
        </v-row>
      </v-form>
    </v-container>
    <!-- <v-alert
      v-if="successMessage != ''"
      type="success"
      tile
    >
      {{ successMessage }}
    </v-alert>
    <v-alert
      v-if="errorMessage != ''"
      type="error"
      tile
    >
      {{ errorMessage }}
    </v-alert> -->
  </div>
</template>

<script>
export default {
  props: {
    claimCost: {
      type: Number,
      required: true,
    },
    balance: {
      type: Number,
      required: true,
    },
    tokens: {
      type: Array,
      required: true,
    },
    redeem: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      random: 0,
      loading: false,
    };
  },
  computed: {
    fieldsCompleted() {
      return this.amount > 0;
    },
    sufficientBalance() {
      return this.balance >= this.claimCost;
    },
  },
  created() {
    setInterval(() => { this.random = (this.random + 1) % this.tokens.length; }, 1000);
  },
  methods: {
    async doRedeem() {
      this.loading = true;
      await this.redeem();
      bus.$emit('update');
      this.loading = false;
    },
  },
};
</script>
