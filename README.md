<!-- HEADER -->
<a href="https://williamhallin.com"><img src="https://raw.githubusercontent.com/whallin/whallin/master/img_header.png" alt="A banner showing the William Hallin logo."></a>

<!-- SHIELDS -->
<p align=center>
  <a href="https://github.com/whallin/high-ping-kicker/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/whallin/high-ping-kicker.svg?style=for-the-badge&color=brightgreen" alt="Shield showing total amount of contributors.">
  </a>
  <img src="https://badges.pufler.dev/visits/whallin/high-ping-kicker?style=for-the-badge">
</p>

<!-- ABOUT -->
## 🎮 high-ping-kicker
high-ping-kicker was created and developed by [@msleeper](https://forums.alliedmods.net/member.php?u=37521), but has now turned into a more inactive resource that sadly isn't being maintained. Hence, why this repository exists. We're here to make sure development of this incredibly useful plugin remains active and fixes are made to existing issues. 

high-ping-kicker lets kick users from your server that exceed the specified amount of delay to your server (ping). This can easily help eliminate players who are lagging far too much to provide a fair chance for others on your network.

<!-- CVARS -->
## 🚀 Cvars
- ``sm_vbping_mintime``			: Minimum playtime before ping check begins. (Default: 30 seconds)
- ``sm_vbping_maxping``			: Maximum player ping. (Default: 500 milliseconds)
- ``sm_vbping_checkrate``		: Period in seconds when rate is checked. (Default: 20 seconds)
- ``sm_vbping_maxwarnings`` 		: Number of warnings before kick. (Default: 3)
- ``sm_vbping_minplayers``		: Minimum number of players before kicking. (Default: 3)
- ``sm_vbping_logactions``		: Log warning and kick actions. 1 = Enabled. 0 = Disabled. (Default: 1)
- ``sm_vbping_showwarnings``	: Enable/disable warning messages. 1 = Enabled. 0 = Disabled. (Default: 1)
- ``sm_vbping_showpublickick``		: Enable/disable public kick message. 1 = Enabled. 0 = Disabled. (Default: 1)
- ``sm_vbping_immunityflag``	: SourceMod admin flag used to grant immunity to all ping checking/kicking. (Default: k)
- ``sm_vbping_ignore_hour_start``		: Start hour when ping check should be disabled. (-1 to disable this feature) (Default: -1)
- ``sm_vbping_ignore_hour_end``		: End hour when ping check should be disabled. (-1 to disable this feature) (Default: -1)

<!-- COMPILE -->
## ▶️ Compile yourself
Make compiling easy with [Spider (https://spider.limetech.io/)](https://spider.limetech.io/) or follow [this guide](https://wiki.alliedmods.net/Compiling_SourceMod_Plugins) written on the AlliedModders wiki.

<!-- CONTRIBUTORS -->
## 🤝 Contributors
<a href="https://github.com/whallin/high-ping-kicker/graphs/contributors"><img src="https://contrib.rocks/image?repo=whallin/high-ping-kicker" /></a>

<!-- LICENSE -->
## ⚖️ License
Copyright © 2021 [William Hallin Multimedia &lt;me@williamhallin.com&gt; (https://www.williamhallin.com)](https://www.williamhallin.com)

whallin/high-ping-kicker is licensed under the ``GPL-3.0`` license. Read more about its meaning and effects [here](https://github.com/whallin/high-ping-kicker/blob/main/LICENSE).
