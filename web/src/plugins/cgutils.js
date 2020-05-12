// Copyright (c) 2020 Curvegrid Inc.
// cgutils.js is Curvegrid's Utility plugin for Vue

import axios from 'axios';
import { utils } from 'ethers';


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
      async callMethod(contract, instance, method, sender, args) {
        try {
          const response = await this.methodPostHelper(contract, instance, method, sender, args);
          return response.data.result.output;
        } catch (e) {
          console.warn(e);
        }
        return null;
      },
      // Sends an axios request to multibaas
      async methodPostHelper(contract, instance, method, sender, args) {
        return axios({
          method: 'POST',
          credentials: 'same-origin',
          url: `http://localhost:3000/api/v0/chains/ethereum/addresses/${contract}/contracts/${instance}/methods/${method}`,
          data: { args: args || [], from: sender },
        });
      },
      // Send a write method to the blockchain.
      // contract: the contract label
      // instance: the instance label
      // method: the name of the read method
      // sender: the from address for the transaction
      // args: the arguments for the method call
      // web3: a handle to the web3 instance
      async sendMethod(contract, instance, method, sender, args, web3) {
        try {
          const response = await this.methodPostHelper(contract, instance, method, sender, args);

          // Send transaction to Blockchain for POST requests only
          const { tx, submitted } = response.data.result;
          let txHash = tx.hash;
          if (!submitted) {
            const signer = web3.getSigner(tx.from);
            const ethersTx = this.formatEthersTx(tx);
            const txResponse = await signer.sendTransaction(ethersTx);
            txHash = txResponse.hash;
          }

          await this.waitForTransactionConfirmation(txHash, web3);

          console.log(response.data.result);
        } catch (e) {
          console.warn(e);
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
