class JingoFarmer extends Pawn
	placeable;

var AnimNodeSlot PriorityAnimSlot;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Fill our ref for our one-shot animnode
	PriorityAnimSlot = AnimNodeSlot(Mesh.FindAnimNode('PrioritySlot'));
}

function HandleMomentum( vector Momentum, Vector HitLocation, class<DamageType> DamageType, optional TraceHitInfo HitInfo )
{
	SetPhysics(PHYS_Falling);
	AddVelocity( Momentum, HitLocation, DamageType, HitInfo );
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Play a hurt animation
	PriorityAnimSlot.PlayCustomAnimByDuration('hurt', 0.28, 0.1, 0.1, false, true);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	GotoState('Dying');
	bReplicateMovement = false;
	bTearOff = true;
	Velocity += TearOffMomentum;
	bPlayedDeath = true;
	PriorityAnimSlot.PlayCustomAnimByDuration('die', 0.28, 0.1, 0.1, false, true);
	SetTimer(0.28, false, 'SetDyingPhysics');
}

simulated function SetDyingPhysics()
{
    Mesh.SetRBChannel(RBCC_Pawn);
    Mesh.SetRBCollidesWithChannel(RBCC_Default, true);
    Mesh.SetRBCollidesWithChannel(RBCC_Pawn, false);
    Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, false);
    Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, false);
    Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, true);
	self.InitRagdoll();
}
	
defaultproperties
{
	ControllerClass=class'JingoAIController_Farmer'
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=false
	BlockRigidBody=true
	LandMovementState=PlayerWalking
	GroundSpeed=200.0
	
	HealthMax = 100
	Health = 100
	
	DrawScale3D=(X=2,Y=2,Z=2)

	Begin Object Name=CollisionCylinder
		CollisionRadius=32
		CollisionHeight=128
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object
	CylinderComponent=CollisionCylinder
	
  	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'JingoCharacters.farmer_rest'
		AnimTreeTemplate=AnimTree'JingoCharacters.farmer_tree'
		AnimSets(0)=AnimSet'JingoCharacters.farmer_anim'
		PhysicsAsset = PhysicsAsset'JingoCharacters.farmer_Physics'
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