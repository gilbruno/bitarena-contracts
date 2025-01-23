// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


interface IBitarenaUpgrade {

    error UnauthorizedUpgrade(address msgSender);

    error UnauthorizedNewImplementationWithNullAddress();
}