class JingoHUD extends HUD;

var float aForwardPercent, aStrafePercent, aLookUpPercent, aTurnPercent;
var JingoPawn JingoPawn;

var string SpeechBubble;
var float SpeechBubbleTime;
var float SpeechBubbleTimeElapsed;
var float ObjectiveAnnounceElapsed;

simulated function DrawHUD()
{
	local JingoPawn P;
	local JingoEnemyPawn_Redcoat RC;
	local array<JingoEnemyPawn_Redcoat> Redcoats;
	local vector ProjectLoc, ProjectDirection, CenterLoc, PlayerLoc, CameraLoc, CameraDirection;
	local rotator ArrowRot, CameraRot;
	local float TextX, TextY, TextPosX, TextPosY;
	
	foreach WorldInfo.AllActors(class'JingoPawn', P)
	{
		JingoPawn = P;
	}
	
	foreach WorldInfo.AllActors(class'JingoEnemyPawn_Redcoat', RC)
	{
		Redcoats.AddItem(RC);
	}
	
	CenterLoc.X = Canvas.ClipX / 2;
	CenterLoc.Y = Canvas.ClipY / 2;
	CenterLoc.Z = -64;
	
	PlayerLoc = Canvas.Project(JingoPawn.Location);
	
	PlayerOwner.GetPlayerViewPoint(CameraLoc, CameraRot);
	CameraDirection = Vector(CameraRot);	
  
	Canvas.DrawColor = RedColor;
	Canvas.Font = class'Engine'.Static.GetSmallFont();
	Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.1);	
	Canvas.DrawText("RawJoyUp: " $JingoPlayerController(PlayerOwner).JRawJoyUp$ " - RawJoyRight: " $JingoPlayerController(PlayerOwner).JRawJoyRight$ " ----+---- RawJoyLookUp: " $JingoPlayerController(PlayerOwner).JRawJoyLookUp$ " RawJoyLookRight: " $JingoPlayerController(PlayerOwner).JRawJoyLookRight);

	Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.15);	
	Canvas.DrawText("aMouseX: " $JingoPlayerController(PlayerOwner).JaMouseX$ " - aMouseY: " $JingoPlayerController(PlayerOwner).JaMouseY);
	
	Canvas.SetPos(Canvas.ClipX * 0.1, Canvas.ClipY * 0.2);	
	Canvas.DrawText("Accel: " $JingoPawn.Acceleration$ " - Velocity: " $JingoPawn.Velocity);

	foreach Redcoats(RC)
	{
		ProjectLoc = Canvas.Project(RC.Location);
		Canvas.SetPos(ProjectLoc.X, ProjectLoc.Y);
		Canvas.DrawText("ID: " $RC.FormationID$ " - State: " $RC.Controller.GetStateName()$ " - Enemy: " $RC.Controller.Enemy);
	}	
	
	// Draw the crosshair
	ProjectLoc = Canvas.Project(JingoPawn.AimPoint);
	Canvas.SetPos(ProjectLoc.X - 16, ProjectLoc.Y - 16);
	Canvas.DrawTile(Texture2D'JingoUI.crosshair', 32, 32, 0, 0, 32, 32, MakeLinearColor(1,0,0,1));
	
	// Draw sticks
	// Calculate stick percentages
	aForwardPercent = (JingoPlayerController(PlayerOwner).JaForward / 1000) * 100;
	aStrafePercent = (JingoPlayerController(PlayerOwner).JaStrafe / 1000) * 100;
	aLookUpPercent = (JingoPlayerController(PlayerOwner).JaLookUp / 209) * 100;
	aTurnPercent = (JingoPlayerController(PlayerOwner).JaTurn / 250) * 100;

	// Left background
	Canvas.DrawColor = WhiteColor;
	Canvas.SetPos((Canvas.ClipX / 4) - 128, Canvas.ClipY - (Canvas.ClipY / 4));
	Canvas.DrawTile(Texture2D'JingoUI.stick_background', 128, 128, 0, 0, 128, 128, MakeLinearColor(1,1,1,1));
	// Right background
	Canvas.SetPos(Canvas.ClipX - (Canvas.ClipX / 4), Canvas.ClipY - (Canvas.ClipY / 4));
	Canvas.DrawTile(Texture2D'JingoUI.stick_background', 128, 128, 0, 0, 128, 128, MakeLinearColor(1,1,1,1));
	
	// Left stick
	Canvas.SetPos(((Canvas.ClipX / 4) - 128) + (JingoPlayerController(PlayerOwner).JRawJoyRight * 48), (Canvas.ClipY - (Canvas.ClipY / 4)) - (JingoPlayerController(PlayerOwner).JRawJoyUp * 48)); 
	Canvas.DrawTile(Texture2D'JingoUI.stick_foreground', 128, 128, 0, 0, 128, 128, MakeLinearColor(1,1,1,1));
	// Right stick
	Canvas.SetPos((Canvas.ClipX - (Canvas.ClipX / 4)) + (JingoPlayerController(PlayerOwner).JRawJoyLookRight * 48), (Canvas.ClipY - (Canvas.ClipY / 4)) + (JingoPlayerController(PlayerOwner).JRawJoyLookUp * 48));
	Canvas.DrawTile(Texture2D'JingoUI.stick_foreground', 128, 128, 0, 0, 128, 128, MakeLinearColor(1,1,1,1));
	
	// Draw objective announce text
	if (JingoGameInfo(WorldInfo.Game).ObjectiveAnnounce)
	{
		Canvas.Font = Font'JingoUI.JingoFont';
		Canvas.StrLen(JingoGameInfo(WorldInfo.Game).CurrentObjectiveName, TextX, TextY);
		Canvas.SetPos((Canvas.ClipX / 2) - (TextX / 2), Canvas.ClipY / 4);
		Canvas.DrawText(JingoGameInfo(WorldInfo.Game).CurrentObjectiveName);
	
		ObjectiveAnnounceElapsed += RenderDelta;
		if (ObjectiveAnnounceElapsed >= 5)
		{
			JingoGameInfo(WorldInfo.Game).ObjectiveAnnounce = false;
			ObjectiveAnnounceElapsed = 0;
		}
	}
	
	// Draw objective arrow
	if (JingoGameInfo(WorldInfo.Game).CurrentObjectiveUsesLocation)
	{
		// Location on screen arrow
		ProjectLoc = Canvas.Project(JingoGameInfo(WorldInfo.Game).CurrentObjectiveLocation);
		ProjectDirection = Normal(ProjectLoc - CameraLoc);
		
		if (VSize(JingoPawn.Location - JingoGameInfo(WorldInfo.Game).CurrentObjectiveLocation) >= 1024)
		{
			ArrowRot = Rotator(ProjectLoc - PlayerLoc);
			ArrowRot.Yaw += 16384;
			Canvas.DrawColor = RedColor;
			ProjectLoc.X = Clamp(ProjectLoc.X, 0, Canvas.ClipX);
			ProjectLoc.Y = Clamp(ProjectLoc.Y, 0, Canvas.ClipY);
			Canvas.SetPos(ProjectLoc.X - 32, ProjectLoc.Y);
			Canvas.DrawRotatedTile(Texture2D'JingoUI.Arrow', ArrowRot, 64, 64, 0, 0, 64, 64, 0.5, 0);
		}
	}
	
	if (SpeechBubble != "")
	{
		// Background
		Canvas.Font = Font'JingoUI.JingoFont';
		Canvas.StrLen(SpeechBubble, TextX, TextY);
		if (TextY < 32)
			TextY = 32;
		TextPosX = (Canvas.ClipX / 2) - (TextX / 2);
		TextPosY = Canvas.ClipY / 4;
		Canvas.SetPos(TextPosX, TextPosY);
		Canvas.DrawTile(Texture2D'enginevolumetrics.Fogsheet.Materials.T_EV_BlankWhite_01', TextX, TextY, 0, 0, 1, 1, MakeLinearColor(255, 255, 255, 255));
		// Edges
		// TL
		Canvas.SetPos(TextPosX - 32, TextPosY - 32);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, 32, 0, 0, 32, 32);
		// Top
		Canvas.SetPos(TextPosX, TextPosY - 32);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', TextX, 32, 32, 0, 32, 32);
		// Bottom
		Canvas.SetPos(TextPosX, TextPosY + TextY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', TextX, 32, 32, 64, 32, 32);		
		// TR
		Canvas.SetPos(TextPosX + TextX, TextPosY - 32);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, 32, 64, 0, 32, 32);
		// Left
		Canvas.SetPos(TextPosX - 32, TextPosY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, TextY, 0, 32, 32, 32);
		// Right
		Canvas.SetPos(TextPosX + TextX, TextPosY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, TextY, 64, 32, 32, 32);
		// BL
		Canvas.SetPos(TextPosX - 32, TextPosY + TextY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, 32, 0, 64, 32, 32);
		// BR
		Canvas.SetPos(TextPosX + TextX, TextPosY + TextY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, 32, 64, 64, 32, 32);
		// Callout
		Canvas.SetPos(TextPosX + 64, TextPosY + TextY);
		Canvas.DrawTile(Texture2D'JingoUI.SpeechBubble', 32, 32, 0, 96, 32, 32);
		
		Canvas.DrawColor = RedColor;
		Canvas.SetPos(TextPosX, TextPosY);
		Canvas.DrawText(SpeechBubble);
		
		SpeechBubbleTimeElapsed += RenderDelta;
		if (SpeechBubbleTimeElapsed >= SpeechBubbleTime)
		{
			SpeechBubble = "";
			SpeechBubbleTimeElapsed = 0;
		}
	}

	super.DrawHUD();
}