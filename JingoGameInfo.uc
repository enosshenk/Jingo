class JingoGameInfo extends GameInfo;

var array<JingoRedcoatFormation> Formations;			// Array of all currently active formation systems

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


