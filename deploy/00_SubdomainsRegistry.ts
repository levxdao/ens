export default async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const token = "0xf474E526ADe9aD2CC2B66ffCE528B1A51B91FCdC";
    const registry = "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e";
    const node = "0xf88903d82aebfe9a5fa03a1a6eb4475330ed9991c9b6ffea0f6d0154a210efbe";
    const resolver = "0x4976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41";

    await deploy("SubdomainsRegistry", {
        from: deployer,
        args: [token, registry, node, resolver],
        log: true,
    });
};
