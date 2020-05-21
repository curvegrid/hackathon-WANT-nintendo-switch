<template>
  <v-container>
    <v-form>
      Deposit a token in the pool to earn WANT tokens
    </v-form>
  </v-container>
</template>

<script>
export default {
  data() {
    return {
      // TODO: populate this list of tokens our platform accepts
      acceptedTokens: [
        {
          name: 'DAI',
          address: '',
        },
      ],
    };
  },
};
</script>
