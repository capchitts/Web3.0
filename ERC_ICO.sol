//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 < 0.9.0;

interface ERC20Interface 
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns(uint balance);
    function transfer(address to, uint tokens) external returns(bool success);

    function allowance(address tokenOwner, address spender) external view returns(uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external  returns(bool success);

    //The indexed keyword helps you to filter the logs to find the wanted data.
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner , address indexed spender , uint tokens);
}

contract Block is ERC20Interface
{
    //state variable
    string public name = "Block";
    string public symbol = "BLK";
    string public decimal = "0";
    
    uint public override totalSupply;
    address public founder;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;
    constructor()
    {
        totalSupply = 100000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address owner) public view override returns(uint balance)
    {
        return balances[owner];
    }

    //transfer to function
    function transfer(address to , uint tokens) public override virtual returns(bool success)
    {
        //check if sender has that much amount
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;

        //emit the event
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    //approve to lend money
    function approve(address spender, uint tokens)public override returns(bool success)
    {
        //lender should have tokens amount of money
        require(balances[msg.sender] >= tokens);
        //non zero token requirement
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    //to check how many owner has allowed the spender any amount
    function allowance(address tokenOwner, address spender) public view override returns(uint remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) public override virtual  returns(bool success)
    {
        //check whether the demanded transfer allowed
        require(allowed[from][to] >= tokens);
        //check is there sufficient balance in from account
        require(balances[from] >=tokens);

        //update tokens in both account
        balances[from] -= tokens;
        balances[to] += tokens;

        return true;
    }

}

contract ICO is Block
{
    address public manager;
    address payable public deposit;

    uint tokenPrice=0.1 ether;

    uint public cap=300 ether;

    uint public raisedAmount;

    uint public icoStart=block.timestamp;
    uint public icoEnd=block.timestamp+3; //1 hour=60*60 seconds;

    uint public tokenTradeTime=icoEnd+3600;

    uint public maxInvest=10 ether;
    uint public minInvest=0.1 ether;

    enum State{beforeStart,afterEnd,running ,halted}

    State public icoState;

    event Invest(address investor,uint value,uint tokens);

    constructor(address payable _deposit)
    {
        deposit=_deposit;
        manager=msg.sender;
        icoState=State.beforeStart;
    }

    modifier onlyManger(){
        require(msg.sender==manager);
        _;
    }

    function halt() public onlyManger{
        icoState=State.halted;
    }
    function resume() public onlyManger{
        icoState=State.running;
    }
    function changeDepositAddr(address payable newDeposit) public onlyManger{
        deposit=newDeposit;
    }

    function getState() public view returns(State)
    {
        if(icoState==State.halted)
        {
            return State.halted;
        }
        else if(block.timestamp<icoStart)
        {
            return State.beforeStart;
        }
        else if(block.timestamp>=icoStart && block.timestamp<=icoEnd)
        {
            return  State.running;
        }
        else
        {
            return State.afterEnd;
        }
    }

    function invest() payable public returns(bool){
        icoState=getState();
        require(icoState==State.running);
        require(msg.value >=minInvest && msg.value <=maxInvest);

        raisedAmount+=msg.value;

        require(raisedAmount<=cap);

        uint tokens=msg.value/tokenPrice; 
        balances[msg.sender]+=tokens;
        balances[founder]-=tokens;
        deposit.transfer(msg.value);

        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }

    function burn() public returns(bool)
    {
        icoState=getState();
        require(icoState==State.afterEnd);
        balances[founder]=0;
        return true;
    }

    function transfer(address to,uint tokens) public override returns(bool success)
    {
        require(block.timestamp>tokenTradeTime);
        super.transfer(to,tokens);
        return true;
    }

    function transferFrom(address from,address to,uint tokens) public override returns(bool success)
    {
        require(block.timestamp>tokenTradeTime);
        Block.transferFrom(from,to,tokens);
        return true;
    }

    receive() external payable{
        invest();
    }

    }

