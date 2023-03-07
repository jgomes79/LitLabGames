const erc20Abi = require("./abis/ERC20Permit.json");
const forwarderAbi = require("./abis/LitlabForwarder.json");
const Web3 = require("web3");
const signer = require("eth-sig-util");

const { Hardfork } = require('@ethereumjs/common');
const { FeeMarketEIP1559Transaction } = require('@ethereumjs/tx');
const Common = require('@ethereumjs/common').default;

const web3 = new Web3(new Web3.providers.HttpProvider("https://goerli.infura.io/v3/ba745d05bef84b44a6bd791b6491ce58"));
const chainId = 97;
const gameAddress = "0x485614eAcc6bC6bC3cfB930aB84CB6BB36FbD0BE";
const tournamentAddress = "0xA12E9d21De900E492eE61B7041430c60F1DF2662";
const tokenAddress = "0xc269647ffCe5655DD6bf5Dd38A819992A5db92d3"; // "0x069Bec3e0e86fD6550db52d2Ee8810c29b0F0410";
const forwarderAddress = "0x01624201B99262b6834f2cac0fEE75885e3720F2";
const account = "0x36fa6b6687891aaeb04447baae984d188c6d63a3";
const accountPrivateKey = Buffer.from("27de286883365a191a0d7b1bd5336af9f062bee3969c3d54088d9ba669705b53", "hex");
const payerPrivateKey = "9739eace8e8769e4f2ac685c3fabf24dbb234f0b60ed0ae657a4fc6313cd6312";

const createPermit = async (spender, value, nonce, deadline) => {
  const Permit = [
    { name: "owner", type: "address" },
    { name: "spender", type: "address" },
    { name: "value", type: "uint256" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ];

  const EIP712Domain = [
    { name: 'name', type: 'string' },
    { name: 'version', type: 'string' },
    { name: 'chainId', type: 'uint256' },
    { name: 'verifyingContract', type: 'address' }
  ];

  const domain = {
    name: 'Goerli USD Coin',
    version: '2',
    chainId: chainId, // parseInt(window.ethereum.networkVersion),
    verifyingContract: tokenAddress
  };

  const permit = { 
    owner: account, 
    spender, 
    value, 
    nonce, 
    deadline
  }

  const msgParams = {
      types: {
          EIP712Domain: EIP712Domain,
          Permit: Permit
      },
      primaryType: "Permit",
      domain: domain,
      message: permit
  };

  const signature = await signer.signTypedMessage(accountPrivateKey, {data: msgParams});

  const y = await signer.recoverTypedMessage({data: msgParams, sig: signature});
  console.log(y);

  return signature;
}

const buildForwarderBaseStruct = (forwarderAddress) => {
    const ForwardRequest = [
      {name: 'from', type: 'address'},
      {name: 'to', type: 'address'},
      {name: 'value', type: 'uint256'},
      {name: 'gas', type: 'uint256'},
      {name: 'nonce', type: 'uint256'},
      {name: 'data', type: 'bytes'}
    ];
  
    const EIP712Domain = [
      {name: 'name', type: 'string'},
      {name: 'version', type: 'string'},
      {name: 'chainId', type: 'uint256'},
      {name: 'verifyingContract', type: 'address'}
    ];
  
    const domain = {
      name: 'LitlabGames',
      version: '1.0.0',
      chainId: chainId, // parseInt(window.ethereum.networkVersion),
      verifyingContract: forwarderAddress
    };
  
    const types = {
      EIP712Domain,
      ForwardRequest
    };
  
    const msgData = {
      types,
      domain,
      primaryType: 'ForwardRequest'
    };
  
    return msgData;
  };

  const signMessage = async (web3, method, params, from) => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.sendAsync(
        {
          method,
          params,
          from
        },
        function (err, result) {
          if (err) reject(err);
          if (result.error) reject(result.error.message);
  
          console.log(result);
          resolve(result.result);
        }
      );
    });
  };

  const buildTx = async (request, signature) => {
    const forwarderContract = new web3.eth.Contract(forwarderAbi, forwarderAddress);
    return await forwarderContract.methods.execute(request, signature);
  }
  
  const signTransaction = async (tx, to) => {
    const payer = await web3.eth.accounts.privateKeyToAccount(payerPrivateKey);
    const gasPrice = await web3.eth.getGasPrice();
    const nonce = await web3.eth.getTransactionCount(payer.address, "pending");
    const gas = await tx.estimateGas({ from: payer.address });
  
    const _tx = {
        type: 2,
        nonce: nonce,
        to: to,
        maxFeePerGas: Number(gasPrice),
        maxPriorityFeePerGas: Number(gasPrice),
        data: tx.encodeABI(),
        gasLimit: Math.round(Number(gas) * 1.2),
        chainId: chainId
    };
  
    const common = new Common({ chain: chainId , hardfork: Hardfork.London })
    const txData = FeeMarketEIP1559Transaction.fromTxData(_tx, { common });
    const signedTx = txData.sign(Buffer.from(payerPrivateKey, "hex"));
    return "0x" + signedTx.serialize().toString("hex");
  }
  
  const sendTransaction = async (signedTx) => {
    return await new Promise(async (resolve, reject) => {
      await web3.eth.sendSignedTransaction(signedTx)
        .once('transactionHash', (hash) => {
          resolve(hash);
        });
    });
  }
  
  const sendTxToRelayer = async (request, signature) => {
    const tx = await buildTx(request, signature);
    const signedTx = await signTransaction(tx, forwarderAddress);
    return sendTransaction(signedTx);
  }

(async () => {
    try {
        const erc20Token = new web3.eth.Contract(erc20Abi, tokenAddress);

        const nonce = await erc20Token.methods.nonces(account).call({from:account});
        const sign = await createPermit(gameAddress, web3.utils.toWei('1000000000'), nonce, 2661766724);
        console.log(sign);
        const signature = sign.substring(2);
        const r = "0x" + signature.substring(0, 64);
        const s = "0x" + signature.substring(64, 128);
        const v = parseInt(signature.substring(128, 130), 16);
        console.log(r);
        console.log(s);
        console.log(v);

        const tx = await erc20Token.methods.permit(account, gameAddress, web3.utils.toWei('1000000000'), 2661766724, v, r, s);
        const signedTx = await signTransaction(tx, tokenAddress);
        const x = await sendTransaction(signedTx);
        console.log(x);

        /*
        const forwarderContract = new web3.eth.Contract(forwarderAbi, forwarderAddress);

        const txAbi = await erc20Token.methods.approve(gameAddress, web3.utils.toWei('1000000000'));
        const from = web3.utils.toChecksumAddress(account);
        const nonce = await forwarderContract.methods.getNonce(from).call({account});
        const gas = await txAbi.estimateGas({from: account});

        const approveRequest = {
          from: account,
          to: tokenAddress,
          value: 0,
          gas: Math.round(Number(gas) * 1.5),
          nonce: parseInt(nonce.toString()),
          data: txAbi.encodeABI()
        };

        const msgParams = {
          message: approveRequest,
          ...buildForwarderBaseStruct(forwarderAddress)
        };

        const signature = await signer.signTypedMessage(accountPrivateKey, {data: msgParams});
        console.log(signature);

        const tx = await sendTxToRelayer(approveRequest, signature);
        console.log(tx);
        */

        console.log('Finished!!');
    } catch (e) {
        console.log('Error main catch', e.toString());
    }
})();