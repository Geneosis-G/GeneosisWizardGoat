class MagicActor extends Actor
	abstract
	implements(MagicActorInterface);

var WizardGoat myMut;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	myMut=WizardGoat(Owner);
}

static function bool IsValidActor(Actor act)
{
	return act != none && !act.bPendingDelete && !act.bHidden;
}
//Empty implementation
function Actor GetMagicActor();
function EnableMagic(Actor act, optional bool enableForever);
function DisableMagic(optional bool forceStop);

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	if(!class.static.IsValidActor(GetMagicActor()))
	{
		DisableMagic();
	}
}

event Destroyed()
{
	myMut.OnMagicActorDestroyed(self);
	super.Destroyed();
}

DefaultProperties
{
	bBlockActors=false
	bCollideActors=true
	Physics=PHYS_None
	CollisionType=COLLIDE_TouchAll
	bIgnoreBaseRotation=true
}