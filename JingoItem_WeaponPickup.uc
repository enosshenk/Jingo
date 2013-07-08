class JingoItem_WeaponPickup extends JingoItem
	placeable;

var() StaticMeshComponent	StaticMeshComponent;
var() class<JingoWeapon> WeaponGiven;

event PostBeginPlay()
{	
	SetCollisionType(COLLIDE_TouchAll);
	
	switch (WeaponGiven)
	{
		case class'JingoWeapon_Musket':
			StaticMeshComponent.SetStaticMesh(StaticMesh'JingoItems.musket_static');
			break;
	}
	
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (JingoPawn(Other) != none)
	{
		JingoPawn(Other).InvManager.CreateInventory(WeaponGiven);
		self.Destroy();
	}
	
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

defaultproperties
{
	Physics = PHYS_Rotating
	RotationRate = (Pitch=0, Roll=0, Yaw=1000)
	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'JingoItems.musket_static';
		bAllowApproximateOcclusion=TRUE
		bForceDirectLightMap=TRUE
		bUsePrecomputedShadows=TRUE
		CollideActors=True
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}