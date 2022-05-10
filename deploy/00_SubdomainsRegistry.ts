import { ethers } from "hardhat";

const TOKEN = "0xdE0C1dC7f2b67705Cca50039418715F9C7F8D53B";
const ENS = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e";
const NODE = "0xf88903d82aebfe9a5fa03a1a6eb4475330ed9991c9b6ffea0f6d0154a210efbe";
const RESOLVER = "0x4976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41";

export default async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const { address } = await deploy("SubdomainsRegistry", {
        from: deployer,
        args: [TOKEN, ENS, NODE, RESOLVER],
        log: true,
    });

    const ENSRegistry = await ethers.getContractFactory("ENSRegistry");
    const ens = await ENSRegistry.attach(ENS);
    await (await ens.setApprovalForAll(address, true)).wait();
    console.log("approved " + address + " for ENSRegistry");
};
