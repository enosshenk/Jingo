class JingoMouseInput extends PlayerInput;

// Stored mouse position. Set to private write as we don't want other classes to modify it, but still allow other classes to access it.
var PrivateWrite IntPoint MousePosition; 

event PlayerInput(float DeltaTime)
{
  local JingoHUD JingoHUD;

  // Handle mouse movement
  // Check that we have the appropriate HUD class
  JingoHUD = JingoHUD(MyHUD);
  if (JingoHUD != None)
  {
	// Add the aMouseX to the mouse position and clamp it within the viewport width
	MousePosition.X = Clamp(MousePosition.X + aMouseX, 0, JingoHUD.SizeX);
	// Add the aMouseY to the mouse position and clamp it within the viewport height
	MousePosition.Y = Clamp(MousePosition.Y - aMouseY, 0, JingoHUD.SizeY);
  }

  Super.PlayerInput(DeltaTime);
}

function SetMousePosition(int X, int Y)
{
  if (MyHUD != None)
  {
    MousePosition.X = Clamp(X, 0, MyHUD.SizeX);
    MousePosition.Y = Clamp(Y, 0, MyHUD.SizeY);
  }
}

defaultproperties
{
}