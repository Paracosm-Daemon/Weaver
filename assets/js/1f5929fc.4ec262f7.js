"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[103],{3905:(e,t,r)=>{r.d(t,{Zo:()=>p,kt:()=>d});var a=r(67294);function n(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function i(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,a)}return r}function o(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?i(Object(r),!0).forEach((function(t){n(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):i(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function s(e,t){if(null==e)return{};var r,a,n=function(e,t){if(null==e)return{};var r,a,n={},i=Object.keys(e);for(a=0;a<i.length;a++)r=i[a],t.indexOf(r)>=0||(n[r]=e[r]);return n}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(a=0;a<i.length;a++)r=i[a],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(n[r]=e[r])}return n}var l=a.createContext({}),c=function(e){var t=a.useContext(l),r=t;return e&&(r="function"==typeof e?e(t):o(o({},t),e)),r},p=function(e){var t=c(e.components);return a.createElement(l.Provider,{value:t},e.children)},g="mdxType",m={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},v=a.forwardRef((function(e,t){var r=e.components,n=e.mdxType,i=e.originalType,l=e.parentName,p=s(e,["components","mdxType","originalType","parentName"]),g=c(r),v=n,d=g["".concat(l,".").concat(v)]||g[v]||m[v]||i;return r?a.createElement(d,o(o({ref:t},p),{},{components:r})):a.createElement(d,o({ref:t},p))}));function d(e,t){var r=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var i=r.length,o=new Array(i);o[0]=v;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s[g]="string"==typeof e?e:n,o[1]=s;for(var c=2;c<i;c++)o[c]=r[c];return a.createElement.apply(null,o)}return a.createElement.apply(null,r)}v.displayName="MDXCreateElement"},45125:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>l,contentTitle:()=>o,default:()=>m,frontMatter:()=>i,metadata:()=>s,toc:()=>c});var a=r(87462),n=(r(67294),r(3905));const i={sidebar_position:2},o="Basic Usage",s={unversionedId:"getting-started/usage",id:"getting-started/usage",title:"Basic Usage",description:"Since Weaver works in a single-script architecture, it's best to start your projects off with it in mind. The most basic version of Weaver works by having one Script in ServerScriptService, and one LocalScript in StarterPlayerScripts, both starting Weaver using their respective WeaverService.Start() and WeaverClient.Start() methods. At the very least, both scripts should look like this:",source:"@site/docs/getting-started/usage.md",sourceDirName:"getting-started",slug:"/getting-started/usage",permalink:"/Weaver/docs/getting-started/usage",draft:!1,editUrl:"https://github.com/paracosm-daemon/weaver/edit/main/docs/getting-started/usage.md",tags:[],version:"current",sidebarPosition:2,frontMatter:{sidebar_position:2},sidebar:"defaultSidebar",previous:{title:"Installation",permalink:"/Weaver/docs/getting-started/installation"},next:{title:"Services",permalink:"/Weaver/docs/communication/services"}},l={},c=[{value:"Methods",id:"methods",level:2},{value:"RemoteSignals",id:"remotesignals",level:2}],p={toc:c},g="wrapper";function m(e){let{components:t,...i}=e;return(0,n.kt)(g,(0,a.Z)({},p,i,{components:t,mdxType:"MDXLayout"}),(0,n.kt)("h1",{id:"basic-usage"},"Basic Usage"),(0,n.kt)("p",null,"Since Weaver works in a ",(0,n.kt)("a",{parentName:"p",href:"https://medium.com/roblox-development/this-article-was-originally-published-in-them-magazines-de995382e352"},"single-script architecture"),", it's best to start your projects off with it in mind. The most basic version of Weaver works by having one ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/Script"},"Script")," in ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/ServerScriptService"},"ServerScriptService"),", and one ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/LocalScript"},"LocalScript")," in ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/StarterPlayerScripts"},"StarterPlayerScripts"),", both starting Weaver using their respective ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverServer#Start"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverService.Start()"))," and ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverClient#Start"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverClient.Start()"))," methods. At the very least, both scripts should look like this:"),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},"local Weaver = require(Weaver) -- Weaver's actual path would likely be somewhere in ReplicatedStorage\n\nWeaver.Start() -- Hooray, Weaver has started!\n")),(0,n.kt)("p",null,"That is the ",(0,n.kt)("em",{parentName:"p"},"bare minimum")," that Weaver needs to run. However, this does not load any ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverServer#WeaverService"},"WeaverServices")," or ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverClient#WeaverController"},"WeaverControllers"),". To do so, we need to create them."),(0,n.kt)("p",null,"Let's create a service on the server. It can be anything, but for this example, a simple \"ping\" service can work. Let's say that we want it to communicate with the client to play ping-pong. When a service is created via ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateService"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverServer.CreateService()")),", it will always have a Client table. There is more detail on how ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverServer#WeaverService"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverServices"))," work in the ",(0,n.kt)("a",{parentName:"p",href:"/docs/communication/services"},"Communication page"),"."),(0,n.kt)("h2",{id:"methods"},"Methods"),(0,n.kt)("p",null,"First, we're going to set up the service, and then specify a method to respond to any client's request to ping the server."),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},'-- This is being ran on the server\n-- CreateService\'s parameter is a table,\n-- and Name has to be specified as a string for it to be registered\nlocal PingService = Weaver.CreateService{ Name = "PingService" }\n-- Since this method is going to be shared with the client, specify it under the Client table\nfunction PingService.Client:Ping(): string\n    return "Pong!"\nend\n-- Finally, start Weaver after our service is created\nWeaver.Start()\n')),(0,n.kt)("p",null,"Then, on the client, you can get PingService using ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverClient#GetService"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverClient.GetService()")),", and run ",(0,n.kt)("inlineCode",{parentName:"p"},"PingService:Ping()")," to play ping-pong."),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},'-- This is being ran on the client\nlocal Weaver = require(Weaver)\n-- Since Weaver needs to be started to get services and controllers,\n-- it\'s done before we call Weaver.GetService()\nWeaver.Start()\n-- Get PingService; it\'s almost like calling game:GetService()\nlocal PingService = Weaver.GetService("PingService")\n-- Start our game of ping-pong on the client\nprint("Ping!")\n\nlocal pingStart: number = os.clock()\n-- Call PingService:Ping(), which will return "Pong!"\nlocal pongOutput: string = PingService:Ping()\n-- Calculate how long it took for the server to respond to our request\nlocal pongTime: number = os.clock() - pingStart\nwarn(pongOutput, "took", pongTime) -- Pong! took 0.31758950000221375\n')),(0,n.kt)("p",null,"Just like that, we've created a service to play ping-pong with. Under the hood, Weaver converts your function into a RemoteFunction, though it is handled as if it were a normal function on the client. If you find Weaver's internal structure while running your game, you can see how it's built:"),(0,n.kt)("p",null,(0,n.kt)("img",{alt:"Ping in the Explorer tree",src:r(43953).Z,width:"512",height:"390"})),(0,n.kt)("h2",{id:"remotesignals"},"RemoteSignals"),(0,n.kt)("p",null,"Let's say that we want to use a ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/RemoteEvent"},"RemoteEvent")," instead, and in this case, for posting a message via ",(0,n.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/MessagingService"},"MessagingService"),". We can use ",(0,n.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateRemoteSignal"},(0,n.kt)("inlineCode",{parentName:"a"},"WeaverServer.CreateRemoteSignal()"))," to create a signal which will be listened to on the client. In practice, the server would look something like this:"),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},'-- This is being ran on the server\nlocal MessagingService = game:GetService("MessagingService")\n-- This will be the topic we post to\nlocal POST_TOPIC: string = "GlobalMessages"\ntype Payload = { name: string, message: string }\n-- First, create PostService\nlocal PostService = Weaver.CreateService{ Name = "PostService" }\n-- Then, create the remote signal.\n-- Trying to use it before Weaver has started will throw an exception\nPostService.Client.SendMessage = Weaver.CreateRemoteSignal()\n-- Connections are done within WeaverInit so that they are ready on WeaverStart\nfunction PostService:WeaverInit(): ()\n    -- First, subscribe to listen to payloads from SendMessage\n    MessagingService:SubscribeAsync(POST_TOPIC, function(received: { Data: Payload, Sent: number }): ()\n        local payload: Payload = received.Data\n        print("Player", payload.name, "sent", payload.message)\n    end)\n    -- Then, connect SendMessage.\n    -- This will take a string as its message parameter\n    self.Client.SendMessage:Connect(function(client: Player, message: string): ()\n        -- Normally, you\'d want to add sanity checks,\n        -- but this is just an example\n        local payload: Payload = {\n            name = client.Name;\n            message = message;\n        }\n        MessagingService:PublishAsync(POST_TOPIC, payload)\n    end)\nend\n')),(0,n.kt)("p",null,"Under the hood, this simply creates a RemoteEvent. This differs from methods as they do not yield when you call ",(0,n.kt)("a",{parentName:"p",href:"/api/RemoteSignal#Fire"},(0,n.kt)("inlineCode",{parentName:"a"},"RemoteSignal:Fire()")),"."),(0,n.kt)("p",null,"Now, let's say that we want to call SendMessage from the client. All we need to do is call ",(0,n.kt)("inlineCode",{parentName:"p"},"SendMessage:Fire()"),", as it gets registered as a ",(0,n.kt)("a",{parentName:"p",href:"/api/RemoteSignal"},"RemoteSignal")," when Weaver starts. This is what the client may look like:"),(0,n.kt)("pre",null,(0,n.kt)("code",{parentName:"pre",className:"language-lua"},'-- This is being ran on the client\nlocal Weaver = require(Weaver)\nWeaver.Start()\n\nlocal PostService = Weaver.GetService("PostService")\nPostService.SendMessage:Fire("Hello from the client!") -- That\'s all!\n')),(0,n.kt)("p",null,"More information on communication can be found on the ",(0,n.kt)("a",{parentName:"p",href:"/docs/communication/services"},"Communications page"),"."))}m.isMDXComponent=!0},43953:(e,t,r)=>{r.d(t,{Z:()=>a});const a=r.p+"assets/images/usage-ping-ab134e5440df0e68dde0015ded78c251.png"}}]);