// const QuestionData = artifacts.require("QuestionData");
const Question = artifacts.require("Question");
// const CyberCredit = artifacts.require("CyberCredit");
// const Robot = artifacts.require("Robot");
const Learning = artifacts.require("Learning");

const Test = artifacts.require("Test");

// const Robot = "0xc1D6ecDDe33fd581fbCDFFb2b6B42EA08e334F2E";
const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
// const CyberCredit = "0xA55cb2d81E01773866F300C3d1c6fD7574Cfa245";


// test BSC
const Robot = "0xFdd66dea9B8ff0eFB73e86C79A233c951854f245";
const CyberCredit = "0xe51819D032f9E969Fec26c8DA77ac4d12a956EfC";

module.exports = function(deployer) {
    // deployer.deploy(Question, QuestionData, CyberCredit);
    // deployer.deploy(Test, "0x0000000000000000000000000000000000000064");
    // deployer.deploy(QuestionData);
    // deployer.deploy(CyberCredit);
    // deployer.deploy(Robot, "Robot", "rNFT")
    deployer.deploy(Learning, Robot, CyberCredit);
}