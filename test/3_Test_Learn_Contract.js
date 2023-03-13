const Learning = artifacts.require("Learning");
const Robot = artifacts.require("Robot");
const CyberCredit = artifacts.require("CyberCredit");

contract("Learning", (accounts) => {
    // let RobotInstance;
    // let CyberCredittInstance;
    let LearningInstance;
    before("Setup contract", async() => {
        // RobotInstance = await Robot.deployed("Robot", "rNFT");
        // CyberCredittInstance = await CyberCredit.deployed();
        LearningInstance = await Learning.deployed();
    })
    it("Set Total Block Learn", async() => {
        const value = 100;
        await LearningInstance.SetTotalBlockLearn(value, { from: accounts[1] });
        assert.notEqual();
    })
})