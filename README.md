# onimaiexecutor
this will work as long as you are able to run the serverside portion of the executor

if you are unable to, you can dismiss the prompt with no reprecussions

there is a lack of interpolated strings and use of next in for loops due to the fact that krnl (and maybe synapse too) does not support luau

this 100% supports krnl but im not sure if anything else does because i can only test on krnl, if you have issues please create an issue or a pull request

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ceat-ceat/onimaiexecutor/main/client/main.lua", true))()
```

[client assets module](https://www.roblox.com/library/12910385605/)


[server module](https://www.roblox.com/library/12910374025/)
