// SPDX-License-Identifier: SEE LICENSE IN LICENSE
// 实现 NFT 荷兰拍
pragma solidity 0.8.24;

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _nftId) external;
}

contract DutchAuction {
  // 拍卖持续时间
  uint256 private constant DURATION = 7 days;
  // 拍卖者，有收钱的能力
  address payable public immutable seller;
  // 拍卖的起始价格
  uint256 public immutable startingPrice;
  // 起拍时间
  uint256 public immutable startAt;
  // 拍卖结束时间
  uint256 public immutable expiresAt;
  // 递减比例
  uint256 public immutable discountRate;
  // nft 变量
  IERC721 public immutable nft;
  // nft 标识符
  uint256 public immutable nftId;


  constructor(
    uint256 _startingPrice,
    uint256 _discountRate,
    address _nft,
    uint256 _nftId
  ) {
    // 拍卖持续时间
    seller = payable(msg.sender); // 合约部署者就是卖方
    startingPrice = _startingPrice;
    startAt = block.timestamp;  // 合约开始时间
    expiresAt = block.timestamp + DURATION;
    discountRate = _discountRate;
    require( startingPrice > _discountRate * DURATION, 'starting price < min');
    nft = IERC721(_nft);
    nftId = _nftId;
  }


  // 获取价格
  function getPrice() public view returns(uint256) {
    uint256 timeElapsed = block.timestamp - startAt; // 时间差
    uint256 discount =  discountRate * timeElapsed;
    return startingPrice - discount;
  }


  // 购买函数, external
  /**
   * 函数只能被外部合约和交易调用，不能被同一个合约内的其他函数调用。 public 则可以
   * external函数不会自动生成getter函数。 public 则会创建
   * 使用external有助于节省Gas，因为它不需要保存函数指针。
   * 
   * 
   * 如果你希望一个函数仅能被外部调用，并且你想节省Gas，你应该使用 external
   */
  function buy() external payable {
    require(block.timestamp < expiresAt, "auction expired"); // 检测是否过期
    uint256 price = getPrice();
    require(msg.value >= price, "ETH < price"); // 检查买家的钱是否住够支付
    nft.transferFrom(seller, msg.sender, nftId); // 将 NFT 从卖家转移到买家
    uint256 refund = msg.value - price; // 假如买家的金额高于价格，则进行退款
    if(refund > 0) {
      payable(msg.sender).transfer(refund); // 日耳曼! 退钱！
    }

    selfdestruct(seller); // 销毁合约，并将剩余的以太币发送给卖家地址 , 但似乎已经被弃用了。
  }
}