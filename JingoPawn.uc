class JingoPawn extends GamePawn
	config(Game);

var vector CamOffset;							// Offset for the camera relative to the player location
var vector AimPoint;							// Aimpoint relative to the player location
var vector HalfAim;
var AnimNodeSlot PriorityAnimSlot;
var SkelControl_CCD_IK ArmIK;
var bool CanIK;
var bool UpdateIK;
var bool JingoPawnMoving;
var float CameraFOV;
var rotator CameraRot;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
	ArmIK = SkelControl_CCD_IK(Mesh.FindSkelControl('LeftArmControl'));
}

function Tick(float DeltaTime)
{
	local vector IKLocation;
	
	if (UpdateIK)
	{
		JingoWeapon(Weapon).SkelMesh.GetSocketWorldLocationAndRotation('ForegripSocket', IKLocation);
		ArmIK.EffectorLocation = IKLocation;
	}
	
	if (VSize(Velocity) > 20)
	{
		JingoPawnMoving = true;
	}
	else
	{
		JingoPawnMoving = false;
	}
	
	super.Tick(DeltaTime);
}

function SetAimPoint(vector AimIn)
{
	if (!JingoGameInfo(WorldInfo.Game).MouseControl)
	{
		AimPoint = GetWeaponStartTraceLocation();
		AimPoint += vect(64,0,0) >> Rotation;
		AimPoint += AimIn;
		
		HalfAim = GetWeaponStartTraceLocation();
		HalfAim += vect(32,0,0) >> Rotation;
		HalfAim += AimIn / 2;
	}
	else
	{
		AimPoint.X = Clamp(AimIn.X, Location.X - 768, Location.X + 768);
		AimPoint.Y = Clamp(AimIn.Y, Location.Y - 768, Location.Y + 768);
		HalfAim = AimPoint / 2;
	}
}

simulated singular event Rotator GetBaseAimRotation()
{
   local rotator   POVRot, tempRot;

   tempRot = Rotation;
   tempRot.Pitch = 0;
   SetRotation(tempRot);
   POVRot = Rotation;
   POVRot.Pitch = 0;

   return POVRot;
}  

simulated event Vector GetWeaponStartTraceLocation(optional Weapon CurrentWeapon)
{
	local vector WeaponSocketLocation;
	
	Mesh.GetSocketWorldLocationAndRotation('WeaponTraceSocket', WeaponSocketLocation);
	
	return WeaponSocketLocation;
} 

simulated function PlayWeaponSwitch(Weapon OldWeapon, Weapon NewWeapon)
{
	CheckIK();
}

function ThrowBomb()
{
	// Function plays our throw animation
	CanIK = false;
	UpdateIK = false;
	ArmIK.SetSkelControlActive(false);
	PriorityAnimSlot.PlayCustomAnimByDuration('throw', 0.71, 0.1, 0.1, false, true);
	SetTimer(0.31, false, 'DoThrowBomb');
	SetTimer(0.5, false, 'CheckIK');
}

function DoThrowBomb()
{
	local JingoItem_Bomb Bomb;
	local vector SpawnLoc, ThrowVelocity;
	
	// Get spawn location and spawn the bomb
	Mesh.GetSocketWorldLocationAndRotation('ThrowSocket', SpawnLoc);
	Bomb = Spawn(class'JingoItem_Bomb', self, , SpawnLoc, Rotation, , true);
	
	// Get a throw velocity
	SuggestTossVelocity(ThrowVelocity, AimPoint, SpawnLoc, 1000, , 0.4);
	
	// Set bomb physics
	Bomb.ApplyImpulse(ThrowVelocity, 300, Bomb.Location);
}

function CheckIK()
{
	local vector IKLocation;
	
	// Set IK if needed
	if (JingoWeapon_Shotgun(Weapon) != none || JingoWeapon_Gatling(Weapon) != none || JingoWeapon_Franklin(Weapon) != none)
	{
		UpdateIK = true;
		ArmIK.SetSkelControlActive(true);
	}
	else
	{
		UpdateIK = false;
		ArmIK.SetSkelControlActive(false);
	}	
}

simulated state Dying
{
	simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		return;
	}
}

simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local float DesiredFOV;
	local rotator DesiredCameraRot;
	
	out_CamLoc = Location;
	out_CamLoc += CamOffset;

//	out_CamRot = Rotator(Location - out_CamLoc);
	DesiredCameraRot = Rotator(HalfAim - out_CamLoc);
	
	if (CameraRot != DesiredCameraRot)
	{
		CameraRot = RLerp(CameraRot, DesiredCameraRot, 0.01);
	}
	
	out_CamRot = CameraRot;
	
	DesiredFOV = 75 + (VSize(Location - AimPoint) / 51.2);
	
	if (CameraFOV != DesiredFOV)
	{
		CameraFOV = Lerp(CameraFOV, DesiredFOV, 0.02);
	}
	
	out_FOV = CameraFOV;
	
	return true;
}


defaultproperties
{
	CamOffset = (X=-768, Y=0, Z=1536)
	
	InventoryManagerClass = class'JingoGame.JingoInventoryManager'
	
  	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'JingoCharacters.testdude'
		AnimTreeTemplate=AnimTree'JingoCharacters.testdude_tree'
		AnimSets(0)=AnimSet'JingoCharacters.testdude_anim'
		PhysicsAsset = PhysicsAsset'JingoCharacters.testdude_Physics'
		CastShadow=true
		bCastDynamicShadow=true
		bOwnerNoSee=false
        BlockRigidBody=true
        CollideActors=true
        BlockZeroExtent=true
		BlockNonZeroExtent=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateSkelWhenNotRendered=FALSE
		bHasPhysicsAssetInstance=true
	End Object
	Mesh=CirclePawnSkeletalMeshComponent
	Components.Add(CirclePawnSkeletalMeshComponent) 
}