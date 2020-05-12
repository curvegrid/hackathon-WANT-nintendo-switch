# vue-node-dapp-sample

Sample DApp using a vue frontend and Node.js proxy.

*Why use a proxy server?* This allows us to keep API keys secret while also narrowing access to the blockchain-only parts of MultiBaas via a whitelist. To allow more endpoints, edit the `proxyWhitelist` array in `server/app.js`.

### Architecture:
```
+----------+
|  Web     | <-----> localhost:8081 front-end served via "yarn run serve" in /web
|  Browser | <-----> localhost:3000 filtering proxy via "yarn start" in /server <-----> localhost:8080 MultiBaas
+----------+
```

## Frontend setup

```
cd web
yarn install
```

### Compiles and hot-reloads for development
```
yarn run serve
```

### Compiles and minifies for production
```
yarn run build
```

### Run your tests
```
yarn run test
```

### Lints and fixes files
```
yarn run lint
```

## Backend setup

```
cd server
yarn install
```

### Set up a config file
Under `server/config/config.json`, create a file like so:
```
{
    "host":"http://localhost:8080",
    "apiKey":"PUT YOUR API KEY HERE"
}

```

### Start the proxy server
```
yarn start
```

Then you can make requests to MultiBaas. Whitelisted endpoints like http://localhost:3000/api/v0/contracts will get forwarded to the designated endpoint. Other endpoints with access to the [UI](http://localhost:3000/login) or [user management](http://localhost:3000/api/v0/users) will be blocked!

```
Access to UI and non-blockchain functionality is not allowed via the proxy server.
```

### Lints and fixes files
```
yarn lint
```

