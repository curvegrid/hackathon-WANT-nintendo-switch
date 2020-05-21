<template>
  <v-container>
    <v-form>
      Redeem WANT tokens for a random token in the pool
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
