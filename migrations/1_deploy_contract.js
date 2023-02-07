// const QuestionData = artifacts.require("QuestionData");
const Quest = artifacts.require("Quest");
// const MockERC20 = artifacts.require("MockERC20");

const Test = artifacts.require("Test");

const QuestionData = "0x6B6F886c2aC84A630cb1A89B12D0B168272379d3";
const GRB = "0x0847a22e3078d05a66Eb27AC35d7D67512A243c5";

module.exports = function(deployer) {
    deployer.deploy(Quest, QuestionData, GRB);
    // deployer.deploy(Test, "0x0000000000000000000000000000000000000064");
    // deployer.deploy(QuestionData);
    // deployer.deploy(MockERC20);
}