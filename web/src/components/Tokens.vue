<template>
  <v-container v-if="tokens !== null">
    <v-row dense>
      <v-col
        v-for="token in tokens"
        :key="token.name"
        cols="3"
      >
        <v-card>
          <v-card-title>
            <v-container fluid>
              <v-row>
                <v-col class="col-auto">
                  {{ token.name }}
                </v-col>
                <v-spacer />
                <v-col
                  class="col-auto"
                >
                  {{ totalTokens === 0 ? 'None' :
                    `${Math.trunc(token.amount / totalTokens * 10000) / 100}%` }}
                </v-col>
              </v-row>
            </v-container>
          </v-card-title>
          <v-card-subtitle>Amount in pool: <b>{{ token.amount }}</b></v-card-subtitle>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  props: {
    tokens: {
      type: Array,
      required: true,
    },
    totalTokens: {
      type: Number,
      required: true,
    },
  },
};
</script>
