// Copyright (c) 2020 Curvegrid Inc.
// cgutils.js is Curvegrid's Utility plugin for Vue

import axios from 'axios';
import { utils } from 'ethers';

const BASE_URL = 'https://ksribvsuevhjdae4pndexvfiuu.multibaas.com';

export default {
  install: (Vue) => {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$_cgutils = {
      // Call a read method on the blockchain.
      // contract: the contract label
      // instance: the instance label
      // method: the name of the read method
      // sender: the from address for the transaction
      // args: the arguments for the method call
      async callMethod(contract, instance, method, sender, apiKey, args, data) {
        try {
          const response = await this.methodPostHelper(contract, instance, method, sender,
            apiKey, args, data);
          return response.data.result.output;
        } catch (e) {
          console.warn(e);
        }
        return null;
      },
      async get(url, apiKey) {
        return axios.get(`${BASE_URL}${url}`, {
          credentials: 'same-origin',
          headers: { Authorization: `Bearer ${apiKey}` },
        });
      },
      async post(url, apiKey, data) {
        return axios({
          method: 'POST',
          credentials: 'same-origin',
          url: `${BASE_URL}${url}`,
          data,
          headers: { Authorization: `Bearer ${apiKey}` },
        });
      },
      // Sends an axios request to multibaas
      async methodPostHelper(contract, instance, method, sender, apiKey, args, data = {}) {
        return this.post(`/api/v0/chains/ethereum/addresses/${contract}/contracts/${instance}/methods/${method}`,
          apiKey,
          { args: args || [], from: sender, ...data });
      },
      // Send a write method to the blockchain.
      // contract: the contract label
      // instance: the instance label
      // method: the name of the read method
      // sender: the from address for the transaction
      // args: the arguments for the method call
      // web3: a handle to the web3 instance
      async sendMethod(contract, instance, method, sender, web3, apiKey, args, data) {
        try {
          const response = await this.methodPostHelper(contract, instance, method, sender,
            apiKey, args, data);

          // Send transaction to Blockchain for POST requests only
          const { tx, submitted } = response.data.result;
          let txHash = tx.hash;
          if (!submitted) {
            const signer = web3.getSigner(tx.from);
            const ethersTx = this.formatEthersTx(tx);
            const txResponse = await signer.sendTransaction(ethersTx);
            txHash = txResponse.hash;
          }

          const receipt = await this.waitForTransactionConfirmation(txHash, web3);

          console.log(response.data.result);
          return receipt;
        } catch (e) {
          console.warn(e);
          return null;
        }
      },
      async waitForTransactionConfirmation(txHash, web3) {
        let txReceipt = null;
        const maxSecondsToWait = 120;
        /* eslint-disable no-await-in-loop */
        for (let i = 0; i < maxSecondsToWait; i += 1) {
          txReceipt = await web3.getTransactionReceipt(txHash);
          if (txReceipt == null) {
            await new Promise((r) => setTimeout(r, 1000));
          } else {
            break;
          }
        }
        console.log(txReceipt);
        return txReceipt;
      },
      // formatEthersTx is used to prepare transactions received from the MultiBaas API
      // for submission on the frontend by ethers.js
      // This helper renames the gas field to gasLimit, and deletes some fields that
      // prevent ethers.js from being able to submit the transaction
      formatEthersTx(txFromAPI) {
        const tx = JSON.parse(JSON.stringify(txFromAPI));
        tx.gasLimit = tx.gas;
        tx.gasPrice = utils.bigNumberify(tx.gasPrice);
        tx.value = utils.bigNumberify(tx.value);
        delete tx.gas;
        delete tx.from;
        delete tx.hash;
        return tx;
      },
    };
  },
};
