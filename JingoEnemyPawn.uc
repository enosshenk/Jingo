class JingoEnemyPawn extends GamePawn
	abstract;

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
	if (DamageType != class'JingoDamageType_Bomb')
	{
		// Play a hurt animation
		PriorityAnimSlot.PlayCustomAnimByDuration('hurt', 0.28, 0.1, 0.1, false, true);
	}
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function TakeRadiusDamage(Controller InstigatedBy, float BaseDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, vector	HurtOrigin, bool bFullDamage, Actor DamageCauser, optional float DamageFalloffExponent=1.f)
{
	SetPhysics(PHYS_Falling);
	Velocity = (Location - HurtOrigin) * (Momentum / 100);
	
	super.TakeRadiusDamage(InstigatedBy, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bFullDamage, DamageCauser, DamageFalloffExponent);
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	SetPhysics(PHYS_Falling);
	Velocity = Location - HitLocation;
	
	return super.Died(Killer, DamageType, HitLocation);
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

function Knockdown()
{
	self.InitRagdoll();
	SetTimer(3, false, 'TermKnockdown');
}

function TermKnockdown()
{
	self.TermRagdoll();
}

simulated state Dying
{
	event TakeDamage(int Damage, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		if ( (Physics == PHYS_None) && (Momentum.Z < 0) )
			Momentum.Z *= -1;

		Velocity += 3 * momentum/(Mass + 200);

		if ( damagetype == None )
		{
			// `warn("No damagetype for damage by "$instigatedby.pawn$" with weapon "$InstigatedBy.Pawn.Weapon);
			DamageType = class'DamageType';
		}
	}
	
	function TakeRadiusDamage(Controller InstigatedBy, float BaseDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, vector	HurtOrigin, bool bFullDamage, Actor DamageCauser, optional float DamageFalloffExponent=1.f)
	{
		Mesh.AddImpulse((Location - HurtOrigin) * (Momentum / 100));
	}
}
	
defaultproperties
{
	WalkingPhysics=PHYS_Walking
	bCollideActors=true
	CollisionType=COLLIDE_BlockAll
	bCollideWorld=true
	bBlockActors=false
	BlockRigidBody=true
	LandMovementState=PlayerWalking
	GroundSpeed=200.0
	InventoryManagerClass = class'JingoGame.JingoInventoryManager'	
	HealthMax = 100
	Health = 100

	Begin Object Name=CollisionCylinder
		CollisionRadius=32
		CollisionHeight=128
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object
	CylinderComponent=CollisionCylinder
	
  	Begin Object Class=SkeletalMeshComponent Name=CirclePawnSkeletalMeshComponent
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