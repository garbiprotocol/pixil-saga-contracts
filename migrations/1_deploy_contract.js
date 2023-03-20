// const QuestionData = artifacts.require("QuestionData");
// const Question = artifacts.require("Question");
// const CyberCredit = artifacts.require("CyberCredit");
// const Robot = artifacts.require("Robot");
const HeroNFT = artifacts.require("HeroNFT");
const Learning = artifacts.require("Learning");

// const Test = artifacts.require("Test");

// const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
const Robot = "0xe7335D1F80bF201D96d9E2CF29388A48191610D3";
const CyberCredit = "0xA55cb2d81E01773866F300C3d1c6fD7574Cfa245";


// test BSC
// const Robot = "0xa5C447aaff3a4239e87D1A760Aba0f25511a5106";
// const CyberCredit = "0xe51819D032f9E969Fec26c8DA77ac4d12a956EfC";
// Learning = 0x1DF916C2a9f6ae4A7009c2da316bF8e57a0634b2

module.exports = function(deployer) {
    // deployer.deploy(Question, QuestionData, CyberCredit);
    // deployer.deploy(Test, "0x0000000000000000000000000000000000000064");
    // deployer.deploy(QuestionData);
    // deployer.deploy(CyberCredit);
    // deployer.deploy(Robot, "Robot", "rNFT");
    deployer.deploy(HeroNFT, "Hero Pixi Saga", "HPG", CyberCredit);
    // deployer.deploy(Learning, Robot, CyberCredit);
}