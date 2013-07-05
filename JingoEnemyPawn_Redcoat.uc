class JingoEnemyPawn_Redcoat extends JingoEnemyPawn
	placeable;

var JingoRedcoatFormation Formation;	// Ref to the formation we're in
var bool InFormation;				// True if we're in formation
var bool LeadingFormation;			// True if we should lead the formation
var int FormationID;				// An int specifying our location in formation

function SetFormation(JingoRedcoatFormation F, int ID)
{
	Formation = F;
	FormationID = ID;
}

function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	// We're dead as hell, notify the formation
	Formation.RemoveRedcoat(self);
	
	return super.Died(Killer, DamageType, HitLocation);
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	// Some asshole shot us, tell the formation leader
	JingoAIController_Redcoat(Formation.Redcoats[0].Controller).SetEnemy(InstigatedBy.Pawn);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

defaultproperties
{
	ControllerClass=class'JingoAIController_Redcoat'

	HealthMax = 100
	Health = 100
	
	bBlocksNavigation = true
	
  	Begin Object Name=CirclePawnSkeletalMeshComponent
		SkeletalMesh = SkeletalMesh'JingoCharacters.farmer_rest'
		AnimTreeTemplate=AnimTree'JingoCharacters.farmer_tree'
		AnimSets(0)=AnimSet'JingoCharacters.farmer_anim'
		PhysicsAsset = PhysicsAsset'JingoCharacters.farmer_Physics'
	End Object
}