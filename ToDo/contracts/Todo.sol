//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.5.0;

contract Todo
{
    struct Task{
        uint id;
        uint date;
        string content;
        string author;
        bool done;
        uint dateComplete;
    }

    mapping(uint => Task) public tasks;
    uint public nextTaskId;

    event TaskCreated(uint id, uint date, string content, string author, bool done);
    event TaskStatusToggled(uint id, bool done, uint date);

    function createTask(string memory _content, string memory _author) external 
    {

        tasks[nextTaskId] = Task(nextTaskId, block.timestamp,_content,_author,false,0);
        emit TaskCreated(nextTaskId, block.timestamp,_content,_author,false);
        nextTaskId++;
    }

    function getTasks() external view returns(Task[] memory)
    {
        Task[] memory _tasks = new Task[](nextTaskId);
        for(uint i=0;i<nextTaskId;i++)
        {
            _tasks[i] = tasks[i];
        }

        return _tasks;
    }

    function toggleDone(uint _id) external{

        require(tasks[_id].id != 0,"Task does not exist");
        Task storage _task = tasks[_id];
        //togle the status
        _task.done = !_task.done;
        _task.dateComplete = _task.done?block.timestamp:0;

        emit TaskStatusToggled(_id, _task.done,_task.dateComplete);
    }


}
