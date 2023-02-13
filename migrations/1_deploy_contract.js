// const QuestionData = artifacts.require("QuestionData");
const Question = artifacts.require("Question");
// const CyberCredit = artifacts.require("CyberCredit");

const Test = artifacts.require("Test");

const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
const CyberCredit = "0xA55cb2d81E01773866F300C3d1c6fD7574Cfa245";

module.exports = function(deployer) {
    deployer.deploy(Question, QuestionData, CyberCredit);
    // deployer.deploy(Test, "0x0000000000000000000000000000000000000064");
    // deployer.deploy(QuestionData);
    // deployer.deploy(CyberCredit);
}