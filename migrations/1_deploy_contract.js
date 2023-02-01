// const QuestionData = artifacts.require("QuestionData");
const Quest = artifacts.require("Quest");
// const MockERC20 = artifacts.require("MockERC20");

const QuestionData = "0xBaeF50cc93Afc84a942559d54D5bF240ad9eD707";
const GRB = "0x0847a22e3078d05a66Eb27AC35d7D67512A243c5";

module.exports = function(deployer) {
    deployer.deploy(Quest, QuestionData, GRB);
    // deployer.deploy(QuestionData);
    // deployer.deploy(MockERC20);
}