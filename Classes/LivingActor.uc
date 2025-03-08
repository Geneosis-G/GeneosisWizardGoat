class LivingActor extends MagicActor;

var Actor livingActor;
var GGGoat master;
var int jumpState;
var float jumpForce;
var int nbJumps;
var bool canJump;
var float closeRadius;

var float sightRadius;

static function bool IsValidActor(Actor actorToMakeLive)
{
	if(!super.IsValidActor(actorToMakeLive))
		return false;

	return GGKactor(actorToMakeLive) != none
		|| GGSVehicle(actorToMakeLive) != none
		|| GGKAsset(actorToMakeLive) != none;
}

function Actor GetMagicActor()
{
	return livingActor;
}

function EnableMagic(Actor target, optional bool enableForever)
{
	local float r, h;
	//WorldInfo.Game.Broadcast(self, "MakeItLive(" $ target $ ")");

	if(livingActor == none)
	{
		livingActor=target;
		SetLocation(livingActor.Location);
		SetBase(livingActor);

		nbJumps=Rand(5)+1;
		jumpState=Rand(nbJumps+1);
		livingActor.GetBoundingCylinder(r, h);
		closeRadius+=r*2;
	}
}

function DisableMagic(optional bool forceStop)
{
	Destroy();
}

function AssignMaster(GGGoat newMaster)
{
	master=newMaster;
}

event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	Live();
}

function Live()
{
	local vector direction;
	local float angle, distance;

	if(livingActor == none)
		return;

	//WorldInfo.Game.Broadcast(self, "velocity(" $ VSize(livingActor.Velocity) $ ")");
	if(VSize(livingActor.Velocity) < 5.f)
	{
		direction=vect(0, 0, 0);
		distance=VSize(GetPawnPosition(master) - livingActor.Location);
		//If goat is close enough (avoid visibility check)
		if(distance<sightRadius && master != none)
		{
			if(distance>closeRadius)
			{
				direction=Normal2D(GetPawnPosition(master) - livingActor.Location);
			}
		}
		else
		{
			if(jumpState == 0)
			{
				angle = FRand()*PI*2;
				direction.x=cos(angle);
				direction.y=sin(angle);
			}
		}

		direction.z=1;
		DoJump(direction);
	}
}

function vector GetPawnPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

function DoJump(vector direction)
{
	local vector vel;

	if(!canJump)
		return;

	canJump=false;
	vel=livingActor.CollisionComponent.GetRBLinearVelocity();
	vel += direction * jumpForce;
	livingActor.CollisionComponent.SetRBLinearVelocity(vel);

	jumpState++;
	if(jumpState > nbJumps)
	{
		jumpState=0;
	}
	SetTimer( 1.0f, false, NameOf( AllowJump ) );
}

function AllowJump()
{
	canJump=true;
}

DefaultProperties
{
	sightRadius=1000.f
	jumpForce=500.f
	nbJumps=3
	canJump=true
	closeRadius=300.f
}