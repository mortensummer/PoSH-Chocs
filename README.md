# PoSH-Chocs
Scripts as part of my own Powershell learning that may help others. YMMV.

The scripts here are not perfect in anyway, but they are what I've created as part of tasks in my day job that needed to be automated
or processes that needed to be done. I fully understand that there maybe quicker or more efficent ways to do what I've done in my
scripts! Feel free to reach out and let me know! 

## Get-MARSAgent.ps1

Until the Microsoft Azure Recovery Services Agent has an automatic update, I wrote this script to solve it for me. It will get the latest MARS Agent, and compare to an existing .exe on the network. If its newer, it will replace it and send me an email. 

We use Lansweeper (http://www.lansweeper.com) at our organisation, and we have an IT repository of installations, in which this exe is part of. Once the file has updated, its a few seconds to push the update out to all servers that require it. 


