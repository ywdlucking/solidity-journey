// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {

    // token array
    IERC20 public token0;
    IERC20 public token1;

    // token storage capacity
    uint public reserve0;
    uint public reserve1;

    // event 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
        );

    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }

    // take the minimum of two numbers
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity){
        // need authorized swap contract first
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // calculate fluidity
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // If adding liquidity for the first time，create L = sqrt(x * y) LP token
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            // If it is not the first time to add liquidity，minted in proportion to the number of tokens added，take the smaller ratio
            // of the two tokens
            liquidity = min(amount0Desired * _totalSupply / reserve0, amount1Desired * _totalSupply /reserve1);
        }

        // check minted the amount of LP
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // update reserves
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // minted LP to liquidity provider
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // remove liquidity and destroy LP
    // tansfer = (liquidity / totalSupply_LP) * reserve
    // @param liquidity 
    function removeLiquidity(uint liquidity) external returns (uint amount0, uint amount1) {
        // 
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        // calculate the number of tokens to be transferred out in proportion to LP
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        // check
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // burn LP
        _burn(msg.sender, liquidity);
        // transfer out
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        // update reserve
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // with the amount of one asset and the reserve of the token  pair, calculate the amount to exchange for another token
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // swap
    // @param amountIn amount of token for swap
    // @param tokenIn the contract address for swap
    // @param amountOutMin minimum amount to swap out for another token
    function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0){
            tokenOut = token1;
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
       
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            tokenOut = token0;
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        // 更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }

}