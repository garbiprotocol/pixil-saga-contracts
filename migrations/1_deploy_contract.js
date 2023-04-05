// const QuestionData = artifacts.require("QuestionData");
// const Quiz = artifacts.require("Quiz");
// const CyberCredit = artifacts.require("CyberCredit");
// const MockGRB = artifacts.require("MockGRB");
// const Robot = artifacts.require("Robot");
// const HeroNFT = artifacts.require("HeroNFT");
// const Learning = artifacts.require("Learning");
const GameController = artifacts.require("GameController");

// const Test = artifacts.require("Test");

const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
const Robot = "0x0731f79d37C84257550528A9Db6ef7BC73DBD402";
const CyberCredit = "0xA55cb2d81E01773866F300C3d1c6fD7574Cfa245";
const MockGRB = "0x570a6cfa0e11f0db8594e6a74b9106d5f21151c0";
const HeroNFT = "0x3BDBCbc35B48E13e726d6cb75EC5F4fDb9653B3A";
const Learning = "0x6A2F9f16cD8f36D5f11d14b71de3847A85055d76";

// test BSC
// const QuestionData = "0x2b31f649a080910EAab6256bB312f58F1adf2d23";
// const Robot = "0xa5C447aaff3a4239e87D1A760Aba0f25511a5106";
// const CyberCredit = "0xe51819D032f9E969Fec26c8DA77ac4d12a956EfC";
// const HeroNFT = "0xdc884AFE99166a6d4Ef899732Ae684b1C1179308";
// const Learning = "0x16eBb9090f7A5Abe6375bb33cDD99d0076c01027";

module.exports = function(deployer) {
    // deployer.deploy(Quiz, QuestionData, CyberCredit);
    // deployer.deploy(Test, "0x0000000000000000000000000000000000000064");
    // deployer.deploy(QuestionData);
    // deployer.deploy(CyberCredit);
    // deployer.deploy(MockGRB);
    // deployer.deploy(Robot, "Robot Pixil Saga", "rNFT");
    // deployer.deploy(HeroNFT, "Hero Pixil Saga", "hNFT");
    // deployer.deploy(Learning, Robot, CyberCredit);
    deployer.deploy(GameController, HeroNFT, Robot, Learning, MockGRB);
}