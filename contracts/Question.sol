// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuestionData.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Question is Ownable
{
    using SafeMath for uint256;

    IQuestionData public QuestionDataContract;
    IERC20 public TokenReward;  // CyberCredit

    mapping(address => uint256) public TimeTheNextToDoQuest;
    mapping(address => uint256) public TimeTheNextSubmit;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;
    mapping(address => mapping(uint256 => uint256)) public ListResultAnswersUser;

    uint256 public DelayToDoQuest = 0;  // block
    uint256 public TotalQuestionContract = 10;
    uint256 public TotalQuestionOnDay = 3;

    uint256 public BonusAnswerCorrect = 10;

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

    constructor(IQuestionData questionDataContract, IERC20 tokenReward) 
    {
        QuestionDataContract = questionDataContract;
        TokenReward = tokenReward;
    }

    function SetQuestionDataContract(IQuestionData newQuestionDataContract) public onlyOwner
    {
        QuestionDataContract = newQuestionDataContract;
    }

    function SetTokenReward(IERC20 newTokenReward) public onlyOwner
    {
        TokenReward = newTokenReward;
    }

    function SetDelayToDoQuest(uint256 newDelayToDoQuest) public onlyOwner
    {
        DelayToDoQuest = newDelayToDoQuest;
    }

    function SetTotalQuestionContract(uint256 newTotalQuestionContract) public onlyOwner
    {
        TotalQuestionContract = newTotalQuestionContract;
    }
    
    function SetTotalQuestionOnDay(uint256 newTotalQuestionOnDay) public onlyOwner
    {
        TotalQuestionOnDay = newTotalQuestionOnDay;
    }

    function SetBonusAnswerCorrect(uint256 newBonusAnswerCorrect) public onlyOwner
    {
        BonusAnswerCorrect = newBonusAnswerCorrect;
    }
    function DoQuestOnDay() public
    {
        address user = msg.sender;
        require(block.number > TimeTheNextToDoQuest[user], "Error To Do Quest: It's not time to ask quest");

        for(uint256 oldResultAnswer = 0; oldResultAnswer < TotalQuestionOnDay; oldResultAnswer++)
        {
            delete ListResultAnswersUser[user][oldResultAnswer];
        }

        uint256 from1 = 0;
        uint256 to1 = TotalQuestionContract.div(TotalQuestionOnDay).sub(1);

        uint256 from2 = to1.add(1);
        uint256 to2 = from2.add(TotalQuestionContract.div(TotalQuestionOnDay).sub(1));

        uint256 from3 = to2.add(1);
        uint256 to3 = TotalQuestionContract.sub(1);

        ListQuestionsUser[user][0] = RandomNumber(0, user, from1, to1);
        ListQuestionsUser[user][1] = RandomNumber(1, user, from2, to2);
        ListQuestionsUser[user][2] = RandomNumber(2, user, from3, to3);

        TimeTheNextToDoQuest[user] = block.number.add(DelayToDoQuest);
    }

    function GetDataQuest(address user) public view returns(
        Question[] memory data,
        uint256 timeTheNextToDoQuest,
        uint256 delayToDoQuest
        )
    {
        data = new Question[](TotalQuestionOnDay);
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];

            (data[indexQuestion].Question,
            data[indexQuestion].Answer0,
            data[indexQuestion].Answer1,
            data[indexQuestion].Answer2,
            data[indexQuestion].Answer3, ) = QuestionDataContract.ListQuestionsContract(questionNumber);
        }
        timeTheNextToDoQuest = (TimeTheNextToDoQuest[user] < block.number) ? 0 : TimeTheNextToDoQuest[user].sub(block.number);
        delayToDoQuest = DelayToDoQuest;
    }

    function SubmitQuestions(uint256[] calldata results) public
    {
        address user = msg.sender;
        require(block.number > TimeTheNextSubmit[user], "Error Submit Question: It's not time to submit yet");

        uint256 totalNumberCorrect = 0;
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
            (,,,,,uint256 resultAnswerQuestionInContract) = QuestionDataContract.ListQuestionsContract(questionNumber);
            uint256 resultAnswerQuestionOfUser = results[indexQuestion];

            if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
            {
                ListResultAnswersUser[user][indexQuestion] = 1; // 1: true, 0: false;
                totalNumberCorrect = totalNumberCorrect.add(1);
            }
            delete ListQuestionsUser[user][indexQuestion];
        }

        if(totalNumberCorrect > 0) DoBonusToken(user, totalNumberCorrect);

        TimeTheNextSubmit[user] = TimeTheNextToDoQuest[user];
    }

    function DoBonusToken(address user, uint256 totalNumberCorrect) private 
    {
        if(TokenReward.balanceOf(address(this)) >= totalNumberCorrect.mul(BonusAnswerCorrect))
        {
            TokenReward.transfer(user, totalNumberCorrect.mul(BonusAnswerCorrect));
        }
        else
        {
            TokenReward.transfer(user, TokenReward.balanceOf(address(this)));
        }
    }  

    function GetResultAnswers(address user) public view returns(
        uint256[] memory data,
        uint256 totalBonusToken
    )
    {
        data =  new uint256[](TotalQuestionOnDay);
        totalBonusToken = 0;

        for(uint256 resultAnswers = 0; resultAnswers < TotalQuestionOnDay; resultAnswers++)
        {
            data[resultAnswers] = ListResultAnswersUser[user][resultAnswers];
            if(ListResultAnswersUser[user][resultAnswers] == 1)
            {
                totalBonusToken = totalBonusToken.add(BonusAnswerCorrect);
            }
        }
    }

    function RandomNumber(uint256 count, address user, uint256 from, uint256 to) public view returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit)));
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count, seed, user)));
        return randomHash % (to - from + 1) + from;
    }
}