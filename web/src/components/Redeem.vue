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
              width="60%"
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
    getEventsFromTxHash: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      random: 0,
      loading: false,
      successMessage: null,
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
      bus.$emit('hide-message');
      this.loading = true;
      const receipt = await this.redeem();
      bus.$emit('update');
      this.loading = false;
      const getEvents = async () => {
        const res = await this.getEventsFromTxHash(receipt.transactionHash, 'Claim');
        if (res.length === 0) {
          // sleep
          await (new Promise((resolve) => setTimeout(resolve, 500)));
          return getEvents();
        }
        return res;
      };
      const events = await getEvents();
      const token = this.tokenFromAddress(events[0].event.inputs[2].value);
      bus.$emit('message', `Congratuations! You have received ONE ${token.name} 🎉🎉🎉`);
    },

    tokenFromAddress(address) {
      return this.tokens.find((v) => v.address === address);
    },
  },
};
</script>
