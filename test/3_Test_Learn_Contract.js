const Learning = artifacts.require("Learning");

contract("Learning", (accounts) => {
    it("Set Total Block Learn", async() => {
        const LearningInstance = await Learning.deployed();
        const value = 100;
        await LearningInstance.SetTotalBlockLearn(value, { from: accounts[0] });

        const newTotalBlockEarn = (
            await LearningInstance.TotalBlockLearn.call(accounts[0])
        ).toNumber();

        assert.equal(newTotalBlockEarn, value, "Ownable: caller is not the owner");
    })
})