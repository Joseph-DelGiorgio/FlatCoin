const Web3 = require('web3');
const web3 = new Web3('YOUR_ETHEREUM_NODE_URL'); // Replace with your Ethereum node URL

async function main() {
  const senderAddress = 'SENDER_ADDRESS';
  const receiverAddress = 'RECEIVER_ADDRESS';
  const privateKey = 'SENDER_PRIVATE_KEY'; // Replace with the private key of the sender

  const senderNonce = await web3.eth.getTransactionCount(senderAddress);

  // Replace with your Flatcoin contract address and ABI
  const flatcoinAddress = 'FLATCOIN_CONTRACT_ADDRESS';
  const flatcoinABI = [...]; // Include the ABI of your Flatcoin contract

  const flatcoinContract = new web3.eth.Contract(flatcoinABI, flatcoinAddress);

  // Amount of Flatcoins to send (in Wei)
  const amount = web3.utils.toBN(web3.utils.toWei('10', 'ether')); // Adjust the amount as needed

  // Encode the transfer function call
  const data = flatcoinContract.methods.transfer(receiverAddress, amount).encodeABI();

  const txObject = {
    from: senderAddress,
    to: flatcoinAddress,
    data: data,
    nonce: senderNonce,
    gas: 21000, // Gas limit
    gasPrice: web3.utils.toWei('50', 'gwei'), // Gas price in Gwei
  };

  const signedTx = await web3.eth.accounts.signTransaction(txObject, privateKey);
  const txReceipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

  console.log(`Transaction hash: ${txReceipt.transactionHash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

