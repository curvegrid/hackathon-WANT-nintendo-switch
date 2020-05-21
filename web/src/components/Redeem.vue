<template>
  <div>
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
    <v-alert
      v-if="success"
      type="success"
      tile
    >
      Congrats, you earned 1 MANA!
    </v-alert>
    <v-alert
      v-if="!success && success != null"
      type="error"
      tile
    >
      Oops, something went wrong
    </v-alert>
  </div>
</template>

<script>
export default {
  data() {
    return {
      amount: 0,
      result: null,
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
        this.success = false;
      }
    },
  },
};
</script>
