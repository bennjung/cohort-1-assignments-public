// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor 
    constructor(address _tokenX, address _tokenY) {
        require(_tokenX != address(0), "tokenX cannot be zero address");
        require(_tokenY != address(0), "tokenY cannot be zero address");
        if (_tokenX == _tokenY) {
            revert("Tokens must be different");
        }

        if (_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        } else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        }
    }

    // add parameters and implement function.
    // this function will determine the initial 'k'.
    function _addLiquidityFirstTime(uint256 xAmount, uint256 yAmount) internal {
        require(xAmount > 0, "Amounts must be greater than 0");
        require(yAmount > 0, "Amounts must be greater than 0");
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmount);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmount);
        xReserve = xAmount;
        yReserve = yAmount;
        k = xReserve * yReserve;

        emit AddLiquidity(xAmount, yAmount);
        
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmount, uint256 yAmount) internal {
        require(xAmount > 0, "tokenX amount cannot be zero");
        require(yAmount > 0, "tokenY amount cannot be zero");
        require(xAmount * yReserve == yAmount * xReserve, "Invaild ratio") ;

        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmount);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmount);
        xReserve += xAmount;
        yReserve += yAmount;
        k = xReserve * yReserve;

        emit AddLiquidity(xAmount, yAmount);

    }

    // complete the function
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external {
        if (k == 0) {
            // add params
            _addLiquidityFirstTime(xAmountIn, yAmountIn);
        } else {
            // add params
            _addLiquidityNotFirstTime(xAmountIn, yAmountIn);
        }
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        uint256 outputAmt = 0;
        require(k > 0, "No liquidity in pool");
        require(xAmountIn > 0 || yAmountIn > 0, "Must swap at least one token");
        require(xReserve >= xAmountIn && yReserve >= yAmountIn, "Insufficient liquidity" );
        
        
        // tokenx -> tokeny
        if (xAmountIn > 0 && yAmountIn == 0) {
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
            outputAmt = yReserve - (k / (xReserve + xAmountIn) );
            IERC20(tokenY).transfer(msg.sender, outputAmt);
            xReserve += xAmountIn;
            yReserve -= outputAmt;
            emit Swap(xAmountIn, outputAmt);
        // tokeny -> tokenx
        } else if (yAmountIn > 0 && xAmountIn == 0) {
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
            outputAmt = xReserve - (k / (yReserve + yAmountIn) );
            IERC20(tokenX).transfer(msg.sender, outputAmt);
            yReserve += yAmountIn;
            xReserve -= outputAmt;
            emit Swap(yAmountIn, outputAmt);
        } else {
            revert("Can only swap one direction at a time");
        }

        

    }
}
