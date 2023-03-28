// const QuestionData = artifacts.require("QuestionData");
// const Quiz = artifacts.require("Quiz");
// const CyberCredit = artifacts.require("CyberCredit");
const MockGRB = artifacts.require("MockGRB");
// const Robot = artifacts.require("Robot");
// const HeroNFT = artifacts.require("HeroNFT");
// const Learning = artifacts.require("Learning");
const GameController = artifacts.require("GameController");

// const Test = artifacts.require("Test");

const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
const Robot = "0xe7335D1F80bF201D96d9E2CF29388A48191610D3";
const CyberCredit = "0xA55cb2d81E01773866F300C3d1c6fD7574Cfa245";
// const MockGRB = "0x0f9c2828A16b20540fc0FF57cf68e9B1CE9a281c";
const HeroNFT = "0xB00519845700513957e7763b8dcFB22d5b225741";
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
    deployer.deploy(MockGRB);
    // deployer.deploy(Robot, "Robot", "rNFT");
    // deployer.deploy(HeroNFT, "Hero Pixil Saga", "NPS");
    // deployer.deploy(Learning, Robot, CyberCredit);
    // deployer.deploy(GameController, HeroNFT, Robot, Learning, MockGRB);
}