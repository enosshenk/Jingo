//
// A class that handles spawning of X amount of redcoats and manages their AI state for formation behavior
//

class JingoRedcoatFormation extends Actor
	placeable;

var() int SpawnAmount;					// Number of redcoats to spawn at runtime. Range 1-12
var() float BreakPercent;				// At what percentage do we release the formation to fight individually? Range 0-100

var array<JingoEnemyPawn_Redcoat> Redcoats;		// An array of our redcoats to handle
var int NumSpawned;

event PostBeginPlay()
{
	// Notify GameInfo that we've started up
	JingoGameInfo(WorldInfo.Game).AddFormation(self);
	
	SpawnAmount = Clamp(SpawnAmount, 1, 12);
	
	// Do a loop and spawn some redcoats
	while (NumSpawned < SpawnAmount)
	{
		if (NumSpawned == 0)
		{
			`log("Spawning formation leader");
			SpawnRedcoat(true);
		}
		else
		{
			`log("Spawning redcoat");
			SpawnRedcoat(false);
		}
	}
	
	super.PostBeginPlay();
}

function SpawnRedcoat(bool MakeLeader)
{
	local JingoEnemyPawn_Redcoat R;
	local vector SpawnLocation;
	
	if (!MakeLeader)
	{
		// Set up a random location
		SpawnLocation = Location;
		SpawnLocation.X += -512 + Rand(512);
		SpawnLocation.Y += -512 + Rand(512);
	}
	else
	{
		SpawnLocation = Location;
	}
	
	// Spawn the actor
	R = Spawn(class'JingoEnemyPawn_Redcoat', self, , SpawnLocation, Rotation);
	
	if (R != none)
	{
		// Append the array of redcoats
		Redcoats.AddItem(R);
		R.SetFormation(self, NumSpawned);
		`log("Spawned Redcoat #" $NumSpawned);
		if (MakeLeader)
		{
			R.LeadingFormation = true;
			`log("Made leader");
		}
		NumSpawned += 1;
	}
}

// Called when one of our redcoats is killed
function RemoveRedcoat(JingoEnemyPawn_Redcoat RC)
{
	local int i;
	
	Redcoats.RemoveItem(RC);
	if (RC.LeadingFormation)
	{
		// Formation leader was killed! Promote some shmuck
		Redcoats[0].LeadingFormation = true;
		Redcoats[0].Controller.GotoState('Leading');
	}
	// Reset everyone's formation IDs
	Foreach Redcoats(RC, i)
	{
		Redcoats[i].FormationID = i;
	}
}
	
defaultproperties
{
	SpawnAmount = 1
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Crowd.T_Crowd_Spawn'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bIsScreenSizeScaled=True
		ScreenSize=0.0025
	End Object
	Components.Add(Sprite)
	
	Begin Object Class=ArrowComponent Name=ArrowComponent0
		ArrowColor=(R=0,G=255,B=128)
		ArrowSize=1.5
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bTreatAsASprite=True
	End Object
	Components.Add(ArrowComponent0)
}