require 'test_helper'

class CitaSync::ApiTest < ActiveSupport::TestCase
  def mock_block_number
    stub_request(:post, "www.cita.com").
      with(body: hash_including({ method: "blockNumber" }), headers: { "Content-Type": "application/json" }).
      to_return(status: 200, body: { jsonrpc: "2.0", id: 83, result: "0x1" }.to_json)
  end

  def mock_get_block_by_number_zero
    result = {
      "version": 0,
      "hash": "0x542ff7aeccbd2b269c36e134e3c0a1be103b389dc9ed90a55c1d506e00b77b81",
      "header": {
        "timestamp": 1529377997246,
        "prevHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "number": "0x0",
        "stateRoot": "0x9b3609aca48d23cadcbab0d768fa0d2187807a23f4ae19742db128a9a64f3bfc",
        "transactionsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "receiptsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "gasUsed": "0x0",
        "proof": nil,
        "proposer": "0x0000000000000000000000000000000000000000"
      },
      "body": {
        "transactions": []
      }
    }

    stub_request(:post, "www.cita.com").
      with(body: hash_including({ method: "getBlockByNumber", params: ["0x0", true] }), headers: { "Content-Type": "application/json" }).
      to_return(status: 200, body: { jsonrpc: "2.0", id: 83, result: result }.to_json)
  end

  def mock_get_block_by_number_one
    result = {
      "version" => 0,
      "hash" => "0xa18f9c384107d9a4fcd2fae656415928bd921047519fea5650cba394f6b6142b",
      "header" => {
        "timestamp" => 1528702183591,
        "prevHash" => "0xda8991b9cbc7f7bc56e94abbd7056dffc501603a4ab6bcaa7e2ed08b3e58e554",
        "number" => "0x1",
        "stateRoot" => "0x048523e8326427968d05673210cc77a8f76e60d0b9170d1bdc1d49c131da9c85",
        "transactionsRoot" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "receiptsRoot" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "gasUsed" => "0x0",
        "proof" => nil,
        "proposer" => "0x91827976af27e1fd405469b00dc8d3b0ea2203f6"
      },
      "body" => {
        "transactions" => [
          {
            "hash": "0xee969624a87a51fc4acc958a3bb83ca32539ee54ebb4215668fe1029eeab59d4",
            "content": "0x0a1d186420e7192a14627306090abab3a6e1400e9345bc60c78a8bef57380112410422a3159ad636e779ad530dfca184ed3f88183f1be05be6dda4ad820791b0798fe1382cb0396c3563cc6d41f743722ea3918beb8fd343079c2b79eb085f699401"
          }
        ]
      }
    }
    stub_request(:post, "www.cita.com").
      with(body: hash_including({ method: "getBlockByNumber", params: ["0x1", true] }), headers: { "Content-Type": "application/json" }).
      to_return(status: 200, body: { jsonrpc: "2.0", id: 83, result: result }.to_json)
  end

  def mock_get_transaction
    result = {
      "hash": "0xee969624a87a51fc4acc958a3bb83ca32539ee54ebb4215668fe1029eeab59d4",
      "content": "0x0a1d186420e7192a14627306090abab3a6e1400e9345bc60c78a8bef57380112410422a3159ad636e779ad530dfca184ed3f88183f1be05be6dda4ad820791b0798fe1382cb0396c3563cc6d41f743722ea3918beb8fd343079c2b79eb085f699401",
      "blockNumber": "0x1",
      "blockHash": "0xa18f9c384107d9a4fcd2fae656415928bd921047519fea5650cba394f6b6142b",
      "index": "0x0"
    }

    stub_request(:post, "www.cita.com").
      with(body: hash_including({ method: "getTransaction", params: ["0xee969624a87a51fc4acc958a3bb83ca32539ee54ebb4215668fe1029eeab59d4"] }), headers: { "Content-Type": "application/json" }).
      to_return(status: 200, body: { jsonrpc: "2.0", id: 83, result: result }.to_json)
  end

  setup do
    mock_block_number
    mock_get_block_by_number_zero
    mock_get_block_by_number_one
    mock_get_transaction
  end

  test "save_block" do
    block = CitaSync::Persist.save_block("0x1")
    assert block.block_number, 1
  end

  def hash
    "0xee969624a87a51fc4acc958a3bb83ca32539ee54ebb4215668fe1029eeab59d4"
  end

  test "save transaction" do
    block = CitaSync::Persist.save_block("0x1")
    transaction = CitaSync::Persist.save_transaction(hash)
    assert transaction.cita_hash, hash
    assert transaction.errors.full_messages.empty?
    assert block, transaction.block
  end

  test "save transaction with block param" do
    block = CitaSync::Persist.save_block("0x1")
    transaction = CitaSync::Persist.save_transaction(hash, block)
    assert transaction.cita_hash, hash
    assert transaction.errors.full_messages.empty?
    assert block, transaction.block
  end

  test "save transaction without block will be fail" do
    transaction = CitaSync::Persist.save_transaction(hash)
    assert_not transaction.errors.full_messages.empty?
  end

  test "save block with transactions" do
    CitaSync::Persist.save_block_with_transactions("0x1")
    block = Block.first
    transaction = Transaction.first
    assert Block.count, 1
    assert Transaction.count, 1
    assert transaction.block_number, block.header["number"]
    assert transaction.block, block
  end

  test "save blocks with transactions with empty db" do
    CitaSync::Persist.save_blocks_with_transactions
    assert Block.count, 2
    assert Transaction.count, 1
  end

  test "save blocks with transactions with exist block" do
    CitaSync::Persist.save_block("0x0")
    CitaSync::Persist.save_blocks_with_transactions
    assert Block.count, 2
    assert Transaction.count, 1
  end
end
