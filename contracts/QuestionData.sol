// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuestionData is Ownable
{
    mapping(uint256 => QuestInfo) public ListQuestionsContract;

    struct QuestInfo
    {
        string Question;
        string Answer0;
        string Answer1;
        string Answer2;
        string Answer3;
        uint256 AnswerResult;
    }

    // only admin
    function CreateQuestion(
        uint256 indexQuest,
        string memory question,
        string memory answer0, string memory answer1,
        string memory answer2, string memory answer3,
        uint256 answerResult) public onlyOwner
    {
        QuestInfo storage Quest = ListQuestionsContract[indexQuest];

        Quest.Question = question;
        Quest.Answer0 = answer0;
        Quest.Answer1 = answer1;
        Quest.Answer2 = answer2;
        Quest.Answer3 = answer3;
        Quest.AnswerResult = answerResult;
    }

}