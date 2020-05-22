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
    </v-alert>
  </div>
</template>

<script>
export default {
  props: {
    successMessage: {
      type: String,
      required: true,
    },
    errorMessage: {
      type: String,
      required: true,
    },
  },
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
