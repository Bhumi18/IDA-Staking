from datetime import datetime
from datetime import timedelta
import json
from unittest import result

# from sqlalchemy import true
from web3 import Web3
import asyncio
import time
import schedule
import os
from dotenv import load_dotenv

load_dotenv()

provider_url = os.getenv("PROVIDER_URL")
my_address = os.getenv("PUBLIC_ADDRESS")
key = os.getenv("KEY")

web3 = Web3(Web3.HTTPProvider(provider_url))
contract_address = "0x3458b3dcd0483c07d9054d04D4Cee61B3a543931"

# contract config
contract_file = open("artifacts/contracts/StakingContract.sol/StakingContract.json")
contract_data = json.load(contract_file)
contract = web3.eth.contract(address=contract_address, abi=contract_data['abi'])

chain_id = 80001
nonce = web3.eth.get_transaction_count(my_address)

def distributeTokens():
    # get the number of publishers in the contract
    publishers = contract.functions.getPublisherId().call()
    print(publishers)
    for i in range(1,publishers+1):
        publisherDetails = contract.functions.publisherDetails(i).call()
        print(publisherDetails)
        if publisherDetails[8]==False:
            if publisherDetails[3]!=0:
                if publisherDetails[5]>=(publisherDetails[5]+86400):
                    after(publisherDetails[0])

def after(id):
    nonce = web3.eth.get_transaction_count(my_address)
    store_transaction = contract.functions.distribute(id).build_transaction(
        {
            "chainId": chain_id,
            "from": my_address,
            "nonce": nonce,
            "gasPrice": web3.eth.gas_price,
        }
    )
    # sign txn.
    signed_store_txn = web3.eth.account.sign_transaction(
        store_transaction, private_key=key
    )
    # send txn.
    send_store_tx = web3.eth.send_raw_transaction(signed_store_txn.rawTransaction)
    print(send_store_tx)
    tx_receipt = web3.eth.wait_for_transaction_receipt(send_store_tx)
    print(tx_receipt)

    #############################

    nonce1 = web3.eth.get_transaction_count(my_address)
    store_transaction1 = contract.functions.afterDistribution(id).build_transaction(
        {
            "chainId": chain_id,
            "from": my_address,
            "nonce": nonce1,
            "gasPrice": web3.eth.gas_price,
        }
    )
    # sign txn.
    signed_store_txn1 = web3.eth.account.sign_transaction(
        store_transaction1, private_key=key
    )
    # send txn.
    send_store_tx1 = web3.eth.send_raw_transaction(signed_store_txn1.rawTransaction)
    print(send_store_tx1)
    tx_receipt1 = web3.eth.wait_for_transaction_receipt(send_store_tx1)
    print(tx_receipt1)
    return


# distributeTokens()

# def sayHello():
#     print("hi")

schedule.every(1).hour.do(distributeTokens)

while True:
    schedule.run_pending()
    time.sleep(1)