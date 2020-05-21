<template>
  <v-container>
    <v-form
      @submit.prevent
    >
      <v-row align="center">
        <v-col
          cols="12"
          sm="3"
        />
        <v-col
          cols="12"
          sm="6"
        >
          <v-text-field
            v-model="amount"
            label="Amount of WANT"
          />
        </v-col>
      </v-row>
      <v-row class="text-center">
        <v-col>
          <v-btn
            color="primary"
            :disabled="!fieldsCompleted"
            @click="redeem()"
          >
            Redeem
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
    };
  },
  computed: {
    fieldsCompleted() {
      return this.amount > 0;
    },
  },
  methods: {
    redeem() {
      if (this.fieldsCompleted) {
        bus.$emit('redeem', this.amount);
        this.amount = 0;
      }
    },
  },
};
</script>
