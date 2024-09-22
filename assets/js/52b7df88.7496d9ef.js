"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[18],{3905:(e,t,a)=>{a.d(t,{Zo:()=>p,kt:()=>m});var n=a(67294);function r(e,t,a){return t in e?Object.defineProperty(e,t,{value:a,enumerable:!0,configurable:!0,writable:!0}):e[t]=a,e}function i(e,t){var a=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),a.push.apply(a,n)}return a}function o(e){for(var t=1;t<arguments.length;t++){var a=null!=arguments[t]?arguments[t]:{};t%2?i(Object(a),!0).forEach((function(t){r(e,t,a[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):i(Object(a)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(a,t))}))}return e}function l(e,t){if(null==e)return{};var a,n,r=function(e,t){if(null==e)return{};var a,n,r={},i=Object.keys(e);for(n=0;n<i.length;n++)a=i[n],t.indexOf(a)>=0||(r[a]=e[a]);return r}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)a=i[n],t.indexOf(a)>=0||Object.prototype.propertyIsEnumerable.call(e,a)&&(r[a]=e[a])}return r}var s=n.createContext({}),c=function(e){var t=n.useContext(s),a=t;return e&&(a="function"==typeof e?e(t):o(o({},t),e)),a},p=function(e){var t=c(e.components);return n.createElement(s.Provider,{value:t},e.children)},v="mdxType",u={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},d=n.forwardRef((function(e,t){var a=e.components,r=e.mdxType,i=e.originalType,s=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),v=c(a),d=r,m=v["".concat(s,".").concat(d)]||v[d]||u[d]||i;return a?n.createElement(m,o(o({ref:t},p),{},{components:a})):n.createElement(m,o({ref:t},p))}));function m(e,t){var a=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var i=a.length,o=new Array(i);o[0]=d;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[v]="string"==typeof e?e:r,o[1]=l;for(var c=2;c<i;c++)o[c]=a[c];return n.createElement.apply(null,o)}return n.createElement.apply(null,a)}d.displayName="MDXCreateElement"},62404:(e,t,a)=>{a.r(t),a.d(t,{assets:()=>s,contentTitle:()=>o,default:()=>u,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var n=a(87462),r=(a(67294),a(3905));const i={sidebar_position:1},o="Services",l={unversionedId:"communication/services",id:"communication/services",title:"Services",description:"WeaverServices are created through the WeaverServer. Services are simply tables, which makes them able to be created in modules, rather than needing to all be created in the same script, which is why Weaver's structure works so well.",source:"@site/docs/communication/services.md",sourceDirName:"communication",slug:"/communication/services",permalink:"/Weaver/docs/communication/services",draft:!1,editUrl:"https://github.com/paracosm-daemon/weaver/edit/main/docs/communication/services.md",tags:[],version:"current",sidebarPosition:1,frontMatter:{sidebar_position:1},sidebar:"defaultSidebar",previous:{title:"Basic Usage",permalink:"/Weaver/docs/getting-started/usage"},next:{title:"Controllers",permalink:"/Weaver/docs/communication/controllers"}},s={},c=[{value:"Construction",id:"construction",level:2},{value:"Signals",id:"signals",level:2},{value:"Properties",id:"properties",level:2},{value:"Initialization",id:"initialization",level:2},{value:"Caveats",id:"caveats",level:2}],p={toc:c},v="wrapper";function u(e){let{components:t,...a}=e;return(0,r.kt)(v,(0,n.Z)({},p,a,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("h1",{id:"services"},"Services"),(0,r.kt)("p",null,(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#WeaverService"},"WeaverServices")," are created through the ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer"},"WeaverServer"),". Services are simply tables, which makes them able to be created in modules, rather than needing to all be created in the same script, which is why Weaver's structure works so well."),(0,r.kt)("h2",{id:"construction"},"Construction"),(0,r.kt)("p",null,"When creating a service, the only key needed in the table is the ",(0,r.kt)("inlineCode",{parentName:"p"},"Name")," property, like so:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Service = Weaver.CreateService({ Name = "Service" })\n')),(0,r.kt)("p",null,"If the extra parenthesis do not fit your coding style, you can also remove them:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Service = Weaver.CreateService{ Name = "Service" }\n')),(0,r.kt)("p",null,"Other values are also able to be specified in this initialization phase, such as the ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," table. This table is what exposes certain methods or signals to the client. It's also possible to specify an ",(0,r.kt)("inlineCode",{parentName:"p"},"Attributes")," table, which are directly tied to Roblox's ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/studio/properties#instance-attributes"},"instance attributes"),"."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Service = Weaver.CreateService{\n    Name = "Service";\n    Attributes = {\n        isService = true;\n    };\n    Client = {\n        Shoot = Weaver.CreateRemoteSignal();\n    };\n}\n')),(0,r.kt)("p",null,"Alongside this, you're also free to add any other items to the service's table itself; the only restrictive table are the ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"Attributes")," tables. The ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," table accepts methods and ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteSignal"},"RemoteSignal")," markers, which are created via ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateRemoteSignal"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverServer.CreateRemoteSignal()"))," and ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateUnreliableSignal"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverServer.CreateUnreliableSignal()")),". Any other type is classified as a ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteProperty"},"RemoteProperty"),", and will be instantiated as one."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Service = Weaver.CreateService{\n    Name = "Service";\n    Client = {\n        ImportantCall = Weaver.CreateRemoteSignal();\n        SomeProperty = 0;\n\n        GetSomething = function(self: WeaverExposed): string\n            return "Something"\n        end;\n    };\n\n    someSharedValue = 123;\n    someOtherSharedValue = "hello";\n    someSharedValues = { 1, 2, 3 };\n}\n')),(0,r.kt)("admonition",{type:"caution"},(0,r.kt)("p",{parentName:"admonition"},"The ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," table is shallow, and all other tables inside of it will be converted into a ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteProperty"},"RemoteProperty")," once Weaver starts.")),(0,r.kt)("h2",{id:"signals"},"Signals"),(0,r.kt)("p",null,"Let's say that we don't want to expose signals to the client, rather, we want to have an event that other services can listen to, like a ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/BindableEvent"},"BindableEvent"),". Weaver implements this through it's built-in class: ",(0,r.kt)("a",{parentName:"p",href:"/api/Signal"},"Signal"),". You are able to create a Signal by using the module located at ",(0,r.kt)("inlineCode",{parentName:"p"},"Weaver.Util.Signal"),". Unlike ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteSignal"},"RemoteSignals"),", these are available as soon as you create them via ",(0,r.kt)("a",{parentName:"p",href:"/api/Signal#new"},(0,r.kt)("inlineCode",{parentName:"a"},"Signal.new()")),"."),(0,r.kt)("p",null,"First, we create our service, which handles our signal:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Signal = Weaver.Util.Signal -- Util is a module, and Signal is already required!\nlocal EventFiringService = Weaver.CreateService{\n    Name = "EventFiringService";\n    SomethingHappened = Signal.new();\n}\nfunction EventFiringService:WeaverStart(): ()\n    -- Fire SomethingHappened in WeaverStart,\n    -- as the connections from other services should be ready\n    self.SomethingHappened:Fire()\nend\n')),(0,r.kt)("p",null,"Then, we create our service which uses this signal:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local EventHandlingService = Weaver.CreateService{ Name = "EventHandlingService" }\nfunction EventHandlingService:WeaverInit(): ()\n    -- First, we get the service\n    local EventFiringService = Weaver.GetService("EventFiringService")\n    -- Then, we connect an event to it\n    EventFiringService.SomethingHappened:Connect(function(): ()\n        print("Something happened!")\n    end)\nend\n')),(0,r.kt)("admonition",{type:"caution"},(0,r.kt)("p",{parentName:"admonition"},"Trying to add ",(0,r.kt)("a",{parentName:"p",href:"/api/signal"},"Signals")," to ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#WeaverService"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverService.Client"))," will not work. The signal will still exist, but it will not be accessible from ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," once Weaver starts, as it cannot be exposed to the client.")),(0,r.kt)("h2",{id:"properties"},"Properties"),(0,r.kt)("p",null,"Weaver also has support for ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteProperty"},"RemoteProperties"),". These are properties which are set by the server, and passed to the client. These properties are also able to be different for every client, while still having a default value. This is great for services which may handle points or currency. As an example, here is a basic money service:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"local MoneyService = Weaver.CreateService{ Name = \"MoneyService\" }\n-- This will initialize as a RemoteProperty once Weaver is initialized\n-- The value this is set to will be used as the default\nMoneyService.Client.Money = 0\nMoneyService.Client.AddMoney = Weaver.CreateRemoteSignal()\n\nlocal Money: RemoteProperty -- This gets initialized in WeaverInit, so it can be used as a shorthand\n-- This is in the server table, so this won't clash with the signal's name\nfunction MoneyService:AddMoney(Client: Player, Amount: number): ()\n    Money:SetFor(Client, Money:GetFor(Client) + Amount)\nend\nfunction MoneyService:WeaverInit(): ()\n    -- Initialize our Money variable\n    Money = self.Client.Money\n    -- Hook our AddMoney signal to the AddMoney function aswell,\n    -- so players can also give themselves money\n    self.Client.AddMoney:Connect(function(Client: number, Amount: number): ()\n        self:AddMoney(Client, Amount)\n    end)\nend\n")),(0,r.kt)("p",null,"This service has a setup where both services and clients can add money to their own values, though you may not want to have a setup like this in production."),(0,r.kt)("p",null,"Similar logic can be used for something that relies on data; if your game uses ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/cloud-services/data-stores"},"DataStores"),", you may want to set a client's value on a ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteProperty"},"RemoteProperty")," to their stored value once they load in. This value could be something like the number of kills a client has reached, or their current level and experience points. Do note that ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteProperty"},"RemoteProperties")," can have all data types that ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/scripting/events/bindable#argument-limitations"},"RemoteEvents")," support."),(0,r.kt)("p",null,"The methods, signals, properties, and attributes all have their own distinct uses. You should pick which one you want to use based on which is the mose optimal for your own use cases."),(0,r.kt)("h2",{id:"initialization"},"Initialization"),(0,r.kt)("p",null,"Trying to utilize services before Weaver has started will result in errors, especially when dealing with ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteSignal"},"RemoteSignals"),". This is because Weaver needs to construct all of the services internally so that they are ready when WeaverInit and WeaverStart are called. This is because the client could have unexpected behavior dealing with services, as issues related to ",(0,r.kt)("a",{parentName:"p",href:"https://en.wikipedia.org/wiki/Race_condition"},"race conditions")," may cause certain signals to be missing, should services be initialized early."),(0,r.kt)("p",null,"Weaver's way of dealing with this is through two methods: WeaverInit and WeaverStart. As outlined in the ",(0,r.kt)("a",{parentName:"p",href:"/docs/extras/execution-model"},"execution model"),", all service objects are internally created and handled, then WeaverInit is called, followed by WeaverStart. These methods are declared by adding ",(0,r.kt)("inlineCode",{parentName:"p"},"Service:WeaverInit()")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"Service:WeaverStart()")," to your service."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local MyMultiStepService = Weaver.CreateService{\n    Name = "Service";\n    Client = {\n        SomeExposedSignal = Weaver.CreateRemoteSignal();\n    };\n}\n\nfunction MyMultiStepService:WeaverInit(): ()\n    print("Init", self.Name)\n    -- Connect some events here...\n    self.Client.SomeExposedSignal:Connect(function(client: Player): ()\n        warn(client, "fired my exposed signal!")\n    end)\nend\nfunction MyMultiStepService:WeaverStart(): ()\n    print("Start", self.Name)\n    -- Fire some events or execute some functions here...\n    local SomeOtherService = Weaver.GetService("SomeOtherService")\n    SomeOtherService.SomeSignal:Fire(123)\nend\n\n-- Output:\n-- Init Service\n-- Start Service\n')),(0,r.kt)("p",null,"As seen above, WeaverInit will always be called before WeaverStart. This goes for all services that you create for your ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateService"},"WeaverServer"),". The best practice is to connect handlers for ",(0,r.kt)("a",{parentName:"p",href:"/api/Signal"},"Signals"),", ",(0,r.kt)("a",{parentName:"p",href:"/api/RemoteSignal"},"RemoteSignals"),", or other ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal"},"RBXScriptSignals")," in WeaverInit, and then execute functions or handle things that update based on the task scheduler \u2014 i.e ",(0,r.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/reference/engine/classes/RunService#PostSimulation"},"RunService.PostSimulation")," \u2014 in WeaverStart. This helps to prevent race conditions from occuring, where you may fire a signal before its handler is connected."),(0,r.kt)("p",null,"Note that anything outside of the ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," table is not exposed to any clients. This is to guarantee safety as you can control what clients are able to access. Usually, for formatting purposes, you may also want to define ",(0,r.kt)("inlineCode",{parentName:"p"},"Client")," outside of ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#CreateService"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverServer.CreateService()")),"."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local Service = Weaver.CreateService{ Name = "Service" }\nService.Client.SomeSignal = Weaver.CreateRemoteSignal()\n\nfunction Service.Client:IncrementNumber(value: number): number\n    return value + 1\nend\n')),(0,r.kt)("p",null,"If you have ModuleScripts for every ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#WeaverService"},"WeaverService"),", you are also able to use ",(0,r.kt)("a",{parentName:"p",href:"/api/WeaverServer#AddServices"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverServer.AddServices()"))," to add all of your services in bulk. This makes it easy to load all of your services at once, and it's especially useful if all of your services are in one location."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"local Weaver = require(Weaver)\n\nWeaver.AddServices(script.Runtime) -- Just an example of a directory to store your services in\nWeaver.Start()\n")),(0,r.kt)("h2",{id:"caveats"},"Caveats"),(0,r.kt)("p",null,"When you first create a Weaver service, a few things will not be available:"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("a",{parentName:"li",href:"/api/WeaverServer#WeaverService"},(0,r.kt)("inlineCode",{parentName:"a"},"WeaverService.Client"))," will not be initialized until Weaver is started, meaning all ",(0,r.kt)("a",{parentName:"li",href:"/api/RemoteSignal"},"RemoteSignals")," will still be markers, and all ",(0,r.kt)("a",{parentName:"li",href:"/api/RemoteProperty"},"RemoteProperties")," will only be the values that you put in the ",(0,r.kt)("inlineCode",{parentName:"li"},"Client")," table."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"Client.Server"),", which is used to access the ",(0,r.kt)("inlineCode",{parentName:"li"},"Server")," table from methods within the ",(0,r.kt)("inlineCode",{parentName:"li"},"Client")," table, will also not be initialized until Weaver has started."),(0,r.kt)("li",{parentName:"ul"},"All of ",(0,r.kt)("inlineCode",{parentName:"li"},"WeaverService"),"'s attribute methods will be unavailable, as Weaver needs to start to initialize the service, which then internally sets the attributes and exposes the methods.")),(0,r.kt)("p",null,"See Weaver's ",(0,r.kt)("a",{parentName:"p",href:"/docs/extras/execution-model"},"execution model")," to understand how services are initialized."))}u.isMDXComponent=!0}}]);