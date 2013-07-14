class JingoPlayerController extends GamePlayerController
	config(Game);

var float JaForward, JaStrafe, JaLookUp, JaTurn, JRawJoyUp, JRawJoyRight, JRawJoyLookUp, JRawJoyLookRight, JaMouseX, JaMouseY;	
var bool MouseControl;
	
exec function GiveMeAGun()
{
	Pawn.InvManager.CreateInventory(class'JingoWeapon_Musket');
	Pawn.InvManager.CreateInventory(class'JingoWeapon_Shotgun');
	Pawn.InvManager.CreateInventory(class'JingoWeapon_Gatling');
	Pawn.InvManager.CreateInventory(class'JingoWeapon_Franklin');
}	

exec function AmericaFuckYeah()
{
	Pawn.InvManager.CreateInventory(class'JingoWeapon_AmericanFlag');
}

exec function SpeechBubble(float Time, string Text)
{
	JingoHUD(myHUD).SpeechBubble = Text;
	JingoHUD(myHUD).SpeechBubbleTime = Time;
}

exec function ThrowBomb()
{
	JingoPawn(Pawn).ThrowBomb();
}

exec function ToggleControl()
{
	if (JingoGameInfo(WorldInfo.Game).MouseControl)
	{
		JingoGameInfo(WorldInfo.Game).MouseControl = false;
	}
	else
	{
		JingoGameInfo(WorldInfo.Game).MouseControl = true;
	}
}
	
state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

   function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
   {
      if( Pawn == None )
      {
         return;
      }

      if (Role == ROLE_Authority)
      {
         // Update ViewPitch for remote clients
         Pawn.SetRemoteViewPitch( Rotation.Pitch );
      }

      Pawn.Acceleration = NewAccel;

      CheckJumpOrDuck();
   }
   
  	function PlayerMove( float DeltaTime )
	{
		local vector			NewAccel, AimVector;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			// Update acceleration.
			NewAccel.X = PlayerInput.aForward;
			NewAccel.Y = PlayerInput.aStrafe;
			NewAccel.Z	= 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
			
			// Modify the pawn aim vector
			if (JingoGameInfo(WorldInfo.Game).MouseControl)
			{
				AimVector = JingoHUD(myHUD).MouseLocation;
			}
			else
			{
				AimVector.X = PlayerInput.RawJoyLookUp * -1 * 512;
				AimVector.Y = PlayerInput.RawJoyLookRight * 512;
			}
			JingoPawn(Pawn).SetAimPoint(AimVector);
			
			// Clone some values for debugging
			 JaForward = PlayerInput.aForward;
			 JaStrafe = PlayerInput.aStrafe;
			 JaLookup = PlayerInput.aLookUp;
			 JaTurn = PlayerInput.aTurn;
			 
			 JRawJoyUp = PlayerInput.RawJoyUp;
			 JRawJoyRight = PlayerInput.RawJoyRight;
			 JRawJoyLookUp = PlayerInput.RawJoyLookUp;
			 JRawJoyLookRight = PlayerInput.RawJoyLookRight;
			 
			 JaMouseX = PlayerInput.aMouseX;
			 JaMouseY = PlayerInput.aMouseY;
		}
	}
}

function UpdateRotation( float DeltaTime )
{
   local Rotator   DeltaRot, newRotation, ViewRotation;

   ViewRotation = Rotator(JingoPawn(Pawn).AimPoint - Pawn.Location);
   if (Pawn!=none)
   {
      Pawn.SetDesiredRotation(ViewRotation);
   }

   ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
   SetRotation(ViewRotation);

   NewRotation = ViewRotation;
   NewRotation.Roll = Rotation.Roll;

   if ( Pawn != None )
      Pawn.FaceRotation(NewRotation, deltatime);

}   

defaultproperties
{
	InputClass=class'JingoMouseInput'
}