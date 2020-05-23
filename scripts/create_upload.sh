#!/bin/bash

upload_file=contracts/_upload.sol
# first five lines from merged files will be ignored
ignore_lines=5

# empty the upload file
echo  > $upload_file

# we will add pragma solidity for the upload file
# and remove first ${ignore_lines} lines from other files

echo "pragma solidity >=0.5.0 <0.6.0;" >> $upload_file
sed 1,${ignore_lines}d contracts/erc20.sol >> $upload_file
sed 1,${ignore_lines}d contracts/UniswapV2Library.sol >> $upload_file
sed 1,${ignore_lines}d contracts/pool.sol >> $upload_file
sed 1,${ignore_lines}d contracts/WANT.sol >> $upload_file

# build the upload contract using sol-merge
yarn build-contracts
