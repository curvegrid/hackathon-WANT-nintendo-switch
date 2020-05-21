<template>
  <v-container>
    <v-row class="text-center">
      <v-col cols="12">
        <v-img
          :src="require('../assets/logo.svg')"
          class="my-3"
          contain
          height="200"
        />
      </v-col>

      <v-col class="mb-4">
        <v-layout column>
          <v-flex>
            <v-btn
              class="primary"
              @click="getTokenName"
            >
              Read from MultiBaas!
            </v-btn>
          </v-flex>
          <v-flex>
            {{ tokenName }}
          </v-flex>
          <br>
          <v-flex>
            <v-btn
              class="primary"
              @click="mintTokens(100)"
            >
              Mint free money!
            </v-btn>
          </v-flex>
          <v-flex>
            {{ tokenSupply }}
          </v-flex>
        </v-layout>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>

export default {
  name: 'Home',
  data: () => ({
    tokenName: '',
    tokenSupply: 0,
    sender: '0xBaC1Cd4051c378bF900087CCc445d7e7d02ad745',
    apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1OTAwMjM2NjcsInN1YiI6IjEifQ.dOD6AydCrB0yLuN8A3wnpJlWBpd7L8XVwiZGoAV0jzU',
  }),
  created() {
    this.getTokenSupply();
    this.getTokenName();
  },
  methods: {
    async getTokenSupply() {
      this.tokenSupply = await this.$root.$_cgutils.callMethod('want8', 'want', 'NumberOftokens', this.sender,
        this.apiKey);
    },
    async getTokenName() {
      this.tokenName = await this.$root.$_cgutils.callMethod('want8', 'want', 'name', this.sender,
        this.apiKey);
    },
    async mintTokens(amount) {
      const args = [`${amount}`];
      await this.$root.$_cgutils.sendMethod('curvetoken', 'mltitoken', 'mint', this.sender, args, this.$root.$_web3,
        this.apiKey);
      this.getTokenSupply();
    },
  },
};
</script>
