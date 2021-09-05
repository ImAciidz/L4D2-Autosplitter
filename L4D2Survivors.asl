state("left4dead2", "")
{

}

state("left4dead2", "1.26")
{
	string32 whatsLoading     : "engine.dll", 0x6CDAF8;
	bool     gameLoading      : "engine.dll", 0x4AA08E;
	bool     cutscenePlaying1 : "client.dll", 0x8A5E24;
	bool     cutscenePlaying2 : "client.dll", 0x8A5F38;
	bool     finaleTrigger1   : "client.dll", 0x9279F0;
	bool     finaleTrigger2   : "client.dll", 0x9279F0;
	bool     scoreboardLoad1  : "client.dll", 0x9152DD;
	bool     scoreboardLoad2  : "client.dll", 0x937D65;
	bool     hasControl       : "client.dll", 0x8C8CCC;
}

state("left4dead2", "1.30")
{
	string32 whatsLoading     : "engine.dll", 0x495EF0;
	bool     gameLoading      : "engine.dll", 0x4A708E;
	bool     cutscenePlaying1 : "client.dll", 0x8A1DA4;
	bool     cutscenePlaying2 : "client.dll", 0x8A1EB8;
	bool     finaleTrigger1   : "client.dll", 0x923970;
	bool     finaleTrigger2   : "client.dll", 0x923970;
	bool     scoreboardLoad1  : "client.dll", 0x91125D;
	bool     scoreboardLoad2  : "client.dll", 0x933CE5;
	bool     hasControl       : "client.dll", 0x8C4C4C;
}

startup
{
	settings.Add("AutomaticGameTime", true, "Automatically set splits to Game Time");
	settings.Add("campaignSplit", true, "Split after each campaign");
	settings.Add("chapterSplit", true, "Split inbetween chapters", "campaignSplit");
	settings.Add("scoreboardVSgameLoading", true, "Split chapters on Scoreboard vs Game Loading", "chapterSplit");
	settings.SetToolTip("scoreboardVSgameLoading", "Toggle between splitting chapters when the scoreboard shows up (checked) and when the loading between chapters begins (unchecked).");
	
	settings.Add("splitOnce", false, "Split only when the run ends");
	settings.SetToolTip("splitOnce","These checkboxes only matter if you didn't check \"Split after each campaign\". They indicate what category you are running.");
	settings.Add("ILs", false, "Individual Levels", "splitOnce");
	settings.SetToolTip("ILs","To select the category you are running, make sure you check all the checkboxes above it.");
	settings.Add("offlineCampaigns", false, "Offline Campaigns", "ILs");
	settings.Add("mainCampaigns", false, "Main Campaigns","offlineCampaigns");
	settings.Add("allCampaigns", false, "All Campaigns","mainCampaigns");
	
	settings.Add("cutscenelessStart", false, "Autostart on cutsceneless campaigns");
	settings.SetToolTip("cutscenelessStart", "Uses a different method to detect when to autostart. Causes the splitter to autostart on every level");
	
	settings.Add("foxyStart2", false, "New start logic");
	settings.SetToolTip("foxyStart2", "Use the new start logic. This should fix autostart for people which it wasn't working. Uncheck to revert to the old method.");
	
	settings.Add("alternateVersionCheck", false, "Manual version selection");
	settings.SetToolTip("alternateVersionCheck", "Select the game version you are running manually. Leave this unchecked for automatic version selection.");
	settings.Add("version126", false, "Version 1.26", "alternateVersionCheck");
	settings.SetToolTip("version126", "original version");
	settings.Add("version130", false, "Version 1.30", "version126");
	settings.SetToolTip("version130", "crackhead version");

	
	settings.Add("debug", false, "See internal values through DebugView");
	settings.SetToolTip("debug", "See the values that the splitter is using to make actions. Requires DebugView. This setting may cause additional lag, so only have this checked if needed.");
	
	settings.CurrentDefaultParent = "debug";
	settings.Add("debugStart", false, "See values referring to autostart");
	settings.Add("debugSplit", false, "See values referring to autosplit");
	
	vars.CurrentVersion="";
	refreshRate=30;
}

init
{
	print("Game process found");
	
	print("Game main module size is " + modules.First().ModuleMemorySize.ToString());
	
	vars.Version130= memory.ReadValue<int>(modules.Where(m => m.ModuleName == "engine.dll").First().BaseAddress + 0x7039E0);
	vars.Version126= memory.ReadValue<int>(modules.Where(m => m.ModuleName == "engine.dll").First().BaseAddress + 0x706990);

	print("Version130 " + vars.Version130);
	print("Version126 " + vars.Version126);

	print("Looking for game version...");
	if(settings["alternateVersionCheck"])
	{
		if(settings["version130"])
			version="1.30";
		else if(settings["version126"])
			version="1.26";
	}
	else
	{
		if(vars.CurrentVersion=="")
		{
			if(vars.Version130==6789)
				version="1.30";
			else if(vars.Version126==6374)
				version="1.26";
			else
				version="";
		}
		else
			version=vars.CurrentVersion;
	}
	if(version=="")
		print("Unknown game version");
	else
		print("Game version is " + version);
	vars.CurrentVersion=version;

	vars.campaignsCompleted=0;
	if(settings["allCampaigns"])
		vars.totalCampaignNumber=13;
	else if (settings["mainCampaigns"])
		vars.totalCampaignNumber=5;
	else if (settings["offlineCampaigns"])
		vars.totalCampaignNumber=2;
	else if (settings["ILs"])
		vars.totalCampaignNumber=1;
	else
		vars.totalCampaignNumber=-1;
	
	if(settings["splitOnce"] && !settings["campaignSplit"])
		print("Total campaign number is " + vars.totalCampaignNumber.ToString());
	
	vars.startRun=false;
	vars.cutsceneStart = DateTime.MaxValue;
	vars.lastSplit=null;
}

start
{
	if (settings["AutomaticGameTime"])
	{
		timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
	if (settings["foxyStart2"])
	{
		// Once we have control after a cutscene plays for at least 1 second, we're ready to start.
		if (current.hasControl && !current.gameLoading)
		{
			if (settings["cutscenelessStart"] || (DateTime.Now - vars.cutsceneStart > TimeSpan.FromSeconds(1)))
			{
				print("CUSTSCENE RAN FOR " + (DateTime.Now - vars.cutsceneStart));
				vars.cutsceneStart = DateTime.MaxValue;
				vars.lastSplit=null;
				return true;
			}
			else if (!settings["cutscenelessStart"] && vars.cutsceneStart != DateTime.MaxValue)
			{
				// Sometimes the game sets 'current.hasControl' to 'false', even when you have control. We need to detect those cases in order to reset the cutscene timer.
				print("FALSE POSITIVE!");
				vars.cutsceneStart = DateTime.MaxValue;
			}
		}
		
		// If we're not loading, and the player does not have control, a cutscene must be playing. Mark the time.
		if (!old.hasControl && !current.hasControl && !current.gameLoading && vars.cutsceneStart == DateTime.MaxValue)
		{
			print("CUSTSCENE START!");
			vars.cutsceneStart = DateTime.Now;
		}
		
		return false;
	}
	else
	{
		if(settings["cutscenelessStart"] && old.gameLoading && !vars.startRun)
		{
			vars.startRun=true;
			print("Autostart triggered");
		}
		
		if(settings["cutscenelessStart"] && !current.gameLoading && current.hasControl && vars.startRun)
		{
			vars.startRun=false;
			print("Run autostarted");
			vars.lastSplit=null;
			return true;
		}
		
		if(old.gameLoading && (current.cutscenePlaying1 || current.cutscenePlaying2) && !vars.startRun)
		{
			vars.startRun=true;
			print("Autostart triggered");
		}
		
		else if(!current.gameLoading && (old.cutscenePlaying1 || old.cutscenePlaying2) && !current.cutscenePlaying1 && !current.cutscenePlaying2 && vars.startRun)
		{
			vars.startRun=false;
			print("Run autostarted");
			vars.lastSplit=null;
			return true;
		}
	}
}

split
{
	//Split on finales
	if(settings["campaignSplit"])
	{
		if((current.finaleTrigger1 || current.finaleTrigger2) && !old.finaleTrigger1 && !old.finaleTrigger2)
		{
			if(current.whatsLoading == vars.lastSplit)
			{
				print("Ceased double split attempt");
				return false;
			}
			print("Split on finale");
			vars.lastSplit = current.whatsLoading;
			return true;
		}
		else if((current.cutscenePlaying1 || current.cutscenePlaying2) && !old.cutscenePlaying1 && !old.cutscenePlaying2 && (current.whatsLoading == "c7m3_port" || current.whatsLoading == "c5m5_bridge" || current.whatsLoading == "c6m3_port" || current.whatsLoading == "c13m4_cutthroatcreek"))
		{
			if(current.whatsLoading == vars.lastSplit)
			{
				print("Ceased double split attempt");
				return false;
			}
			print("Split on THE BEST CAMPAIGN EVER");
			vars.lastSplit = current.whatsLoading;
			return true;
		}
		//Split inbetween chapters
		if(settings["chapterSplit"])
		{
			if(settings["scoreboardVSgameLoading"])
			{
				if(!current.finaleTrigger1 && !current.finaleTrigger2 && !old.scoreboardLoad1 && !old.scoreboardLoad2 && (current.scoreboardLoad1 || current.scoreboardLoad2))
				{
					print("Split at the end of a chapter at the scoreboard");
					vars.lastSplit = current.whatsLoading; // should help prevent finale split failure if user's timer doesn't start automatically
					return true;
				}
			}
			else
			{
				if(!current.finaleTrigger1 && !current.finaleTrigger2 && !old.gameLoading && current.gameLoading && (current.scoreboardLoad1 || current.scoreboardLoad2))
				{
					print("Split at the end of a chapter when it began to load");
					vars.lastSplit = current.whatsLoading; // should help prevent finale split failure if user's timer doesn't start automatically
					return true;
				}
			}
		}
	}
	
	
	//Split only when the run ends
	if(settings["splitOnce"])
	{
		if((current.finaleTrigger1 || current.finaleTrigger2) && !old.finaleTrigger1 && !old.finaleTrigger2)
		{
			if(current.whatsLoading == vars.lastSplit)
			{
				print("Ceased double split attempt");
				return false;
			}
			vars.lastSplit = current.whatsLoading;
			vars.campaignsCompleted++;
			print("Campaign count is now " + vars.campaignsCompleted.ToString());
		}
		else if((current.cutscenePlaying1 || current.cutscenePlaying2) && !old.cutscenePlaying1 && !old.cutscenePlaying2 && (current.whatsLoading == "c7m3_port" || current.whatsLoading == "c5m5_bridge" || current.whatsLoading == "c6m3_port"  || current.whatsLoading == "c13m4_cutthroatcreek"))
		{
			if(current.whatsLoading == vars.lastSplit)
			{
				print("Ceased double split attempt");
				return false;
			}
			vars.lastSplit = current.whatsLoading;
			vars.campaignsCompleted++;
			print("Finished THE BEST CAMPAIGN EVER and the campaign sum is now " + vars.campaignsCompleted.ToString());
		}
		if(vars.campaignsCompleted==vars.totalCampaignNumber)
		{
			print("Ended the run.");
			return true;
		}
	}
}

isLoading
{
	return current.gameLoading;
}

update
{
	if(settings["debug"])
	{
		if(settings["debugStart"]) 
		{
			print("Autostart:\n current.gameLoading = " + current.gameLoading.ToString() +
			"\n current.cutscenePlaying1 = " + current.cutscenePlaying1.ToString() +
			"\n current.cutscenePlaying2 = " + current.cutscenePlaying2.ToString() +
			"\n current.hasControl = " + current.hasControl.ToString() +
			"\n vars.startRun = " + vars.startRun.ToString());
		}
		if(settings["debugSplit"])
		{
			print("Autosplit:\n current.finaleTrigger1 = " + current.finaleTrigger1.ToString() +
			"\n current.finaleTrigger2 = " + current.finaleTrigger2.ToString() +
			"\n current.cutscenePlaying1 = " + current.cutscenePlaying1.ToString() +
			"\n current.cutscenePlaying2 = " + current.cutscenePlaying2.ToString() +
			"\n current.whatsLoading = " + current.whatsLoading);
			if(settings["chapterSplit"])
			{
				print(" current.scoreboardLoad1 = " + current.scoreboardLoad1.ToString() +
				"\n current.scoreboardLoad2 = " + current.scoreboardLoad2.ToString() +
				"\n current.gameLoading = " + current.gameLoading.ToString());
			}
			if(settings["splitOnce"])
			{
				print(" vars.campaignsCompleted = " + vars.campaignsCompleted.ToString() +
				"\n vars.totalCampaignNumber = " + vars.totalCampaignNumber.ToString());
			}
		}
	}
	
	if(version == "")
		return false;
}

exit
{
	print("Game closed.");
}