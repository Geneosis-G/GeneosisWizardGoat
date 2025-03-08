class Meteor extends GGKActor;

var bool earthquakeAllowed;
var StaticMeshComponent myMesh;

var ParticleSystem earthquakeTemplate;
var SoundCue earthquakeSound;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	myMesh.SetNotifyRigidBodyCollision(true);
	myMesh.ScriptRigidBodyCollisionThreshold=1;
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	//WorldInfo.Game.Broadcast(self, "RBCollision(" $ Velocity.Z $ ")");
	super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex );
	
	if(Velocity.Z<-1000)
	{
		Earthquake(-Velocity.Z);
	}
}

//Shockwave that that ragdoll creatures and shake objects
function Earthquake(float power)
{
	local float r, h;
	local vector effectLoc;
	
	if(!earthquakeAllowed)
	{
		return;
	}
	GetBoundingCylinder(r, h);
	earthquakeAllowed=false;
	
	//WorldInfo.Game.Broadcast(self, "Earthquake!");
	HurtRadius(power*power, 2.f*Sqrt(power*100.f), class'GGDamageTypeZombieSurvivalMode', power*10.f, Location, , none);
	
	effectLoc=Location;
	effectLoc.Z-=h;
	WorldInfo.MyEmitterPool.SpawnEmitter( earthquakeTemplate, effectLoc );
	PlaySound( earthquakeSound );
	
	//Disable earthquake to avoid multiple collisions to trigger multiple earthquakes
	SetTimer( 1.0f, false, NameOf( allowEartquake ) );
}

function allowEartquake()
{
	earthquakeAllowed=true;
}

DefaultProperties
{
	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Boulder.Mesh.Boulder_01'
		bUsePrecomputedShadows=false
	End Object
	myMesh=StaticMeshComponent0
	
	earthquakeTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Buttslam_01'
	earthquakeSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Warrior_Stomp_Cue'

	bNoDelete=false
	
	earthquakeAllowed=true
}