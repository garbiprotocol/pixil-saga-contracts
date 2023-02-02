// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuestionData.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Quest is Ownable
{
    using SafeMath for uint256;

    IQuestionData public QuestionDataContract;
    IERC20 public TokenEarn;

    mapping(address => uint256) public TimeTheNextToDoQuest;
    mapping(address => uint256) public TimeTheNextSubmit;
    mapping(address => mapping(uint256 => uint256)) public ListQuestionsUser;

    uint256 public DelayToDoQuest = 0;
    uint256 public TotalQuestionContract = 100;
    uint256 public TotalQuestionOnDay = 3;

    struct Question
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
    }

    constructor(IQuestionData questionDataContract, IERC20 tokenEarn) 
    {
        QuestionDataContract = questionDataContract;
        TokenEarn = tokenEarn;
    }

    function SetQuestionDataContract(IQuestionData newQuestionDataContract) public onlyOwner
    {
        QuestionDataContract = newQuestionDataContract;
    }

    function SetTokenEarn(IERC20 newTokenEarn) public onlyOwner
    {
        TokenEarn = newTokenEarn;
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

    function ToDoQuestOnDay(address user) public
    {
        require(block.timestamp > TimeTheNextToDoQuest[user], "Error To Do Quest: It's not time to ask quest");

        // for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        // {
        //     ListQuestionsUser[user][indexQuestion] = RandomNumber(indexQuestion);
        // }

        // test
        ListQuestionsUser[user][0] = 0;
        ListQuestionsUser[user][1] = 1;
        ListQuestionsUser[user][2] = 2;

        TimeTheNextToDoQuest[user] = block.timestamp.add(DelayToDoQuest);
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
        timeTheNextToDoQuest = TimeTheNextToDoQuest[user];
        delayToDoQuest = DelayToDoQuest;
    }

    function SubmidQuestions(address user, uint256[] calldata results) public
    {
        require(block.timestamp > TimeTheNextSubmit[user], "Error Submit Question: It's not time to submit yet");

        uint256 totalNumberCorrect = 0;
        for(uint256 indexQuestion = 0; indexQuestion < TotalQuestionOnDay; indexQuestion++)
        {
            uint256 questionNumber = ListQuestionsUser[user][indexQuestion];
            (,,,,,uint256 resultAnswerQuestionInContract) = QuestionDataContract.ListQuestionsContract(questionNumber);
            uint256 resultAnswerQuestionOfUser = results[indexQuestion];

            if(resultAnswerQuestionOfUser == resultAnswerQuestionInContract)
            {
                totalNumberCorrect = totalNumberCorrect.add(1);
            }
            delete ListQuestionsUser[user][indexQuestion];
        }

        if(totalNumberCorrect > 0) BonusToken(user, totalNumberCorrect);

        TimeTheNextSubmit[user] = TimeTheNextToDoQuest[user];
    }

    function BonusToken(address user, uint256 totalNumberCorrect) private 
    {
        uint256 bonusAnswerCorrect = 10;
        if(TokenEarn.balanceOf(address(this)) > totalNumberCorrect.mul(bonusAnswerCorrect))
        {
            TokenEarn.transfer(user, totalNumberCorrect.mul(bonusAnswerCorrect));
        }
        else
        {
            TokenEarn.transfer(user, TokenEarn.balanceOf(address(this)));
        }
    }  

    function RandomNumber(uint256 count) public view returns(uint256)
    {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, count)));
        return randomHash % (TotalQuestionContract + 1);
    }
}