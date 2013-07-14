class JingoGameInfo extends GameInfo;

var array<JingoRedcoatFormation> Formations;			// Array of all currently active formation systems
var array<JingoItem_Objective> Objectives;

var int CurrentObjectiveIndex;
var string CurrentObjectiveName;
var vector CurrentObjectiveLocation;
var bool CurrentObjectiveUsesLocation;
var bool ObjectiveAnnounce;
var bool MouseControl;

event PostBeginPlay()
{
	local JingoItem_Objective O;
	
	foreach WorldInfo.AllActors(class'JingoItem_Objective', O)
	{
		Objectives.InsertItem(O.ObjectiveNumber, O);
		`log("Found Objective #" $O.ObjectiveNumber$ ", " $O.ObjectiveName);
	}
	
	CurrentObjectiveName = Objectives[0].ObjectiveName;
	if (Objectives[0].UseLocation)
	{
		CurrentObjectiveLocation = Objectives[0].Location;
		CurrentObjectiveUsesLocation = true;
	}
	else if (Objectives[0].ObjectiveType == O_Timer)
	{
		SetTimer(Objectives[0].ObjectiveTimer, false, 'NextObjective');
		`log("Waiting " $Objectives[0].ObjectiveTimer$ " for objective #1");
	}
	
	Objectives[0].ActivateObjective();
	
	if (Objectives[0].AnnounceOnHUD)
	{
		ObjectiveAnnounce = true;
	}
	
	super.PostBeginPlay();
}

function NextObjective()
{
	CurrentObjectiveIndex += 1;
	
	CurrentObjectiveName = Objectives[CurrentObjectiveIndex].ObjectiveName;
	if (Objectives[CurrentObjectiveIndex].UseLocation)
	{
		CurrentObjectiveLocation = Objectives[CurrentObjectiveIndex].Location;
		CurrentObjectiveUsesLocation = true;
	}
	else if (Objectives[CurrentObjectiveIndex].ObjectiveType == O_Timer)
	{
		SetTimer(Objectives[CurrentObjectiveIndex].ObjectiveTimer, false, 'NextObjective');
	}
	
	if (Objectives[CurrentObjectiveIndex].AnnounceOnHUD)
	{
		ObjectiveAnnounce = true;
	}
	else
	{
		ObjectiveAnnounce = false;
	}
	
	Objectives[CurrentObjectiveIndex].ActivateObjective();
	Objectives[CurrentObjectiveIndex - 1].DeactivateObjective();
	`log("NextObjective() called, new objective #" $CurrentObjectiveIndex$ " - " $CurrentObjectiveName);
}

function AddFormation(JingoRedcoatFormation F)
{
	Formations.AddItem(F);
}

function RemoveFormation(JingoRedcoatFormation F)
{
	Formations.RemoveItem(F);
}

auto State PendingMatch
{
Begin:
	StartMatch();
}

defaultproperties
{
	HUDType=class'JingoGame.JingoHUD'
	PlayerControllerClass=class'JingoGame.JingoPlayerController'
	DefaultPawnClass=class'JingoGame.JingoPawn'
	bDelayedStart=false
}


