import Vue from 'vue';
import App from './App.vue';
import router from './router';
import vuetify from './plugins/vuetify';
import cgutils from './plugins/cgutils';

Vue.use(cgutils);

Vue.config.productionTip = false;

// Creation of the bus for emitting events from children to non-parent components
window.bus = new Vue();

new Vue({
  router,
  vuetify,
  render: (h) => h(App),
}).$mount('#app');
