class MagicBallActor extends Actor;

var int currentMType;
var bool isMagicActive;
var bool effect;
var Actor grabbedItem;
var bool oldNPCStandUp;
var float magicRadius;
var GGGoat wizard;
var WizardGoatComponent myComp;

var ParticleSystem magicParticleTemplate;
var ParticleSystemComponent magicParticle;
var SoundCue magicSound;
var AudioComponent mGlobalAC;
var InterpCurveFloat mGlobalVolume;

var BurningActor burningComp;
var ParticleSystem explosionParticleTemplate;
var SoundCue explosionSound;
var ParticleSystem fireParticleTemplate;
var ParticleSystemComponent fireParticle;

var ParticleSystem windParticleTemplate;
var ParticleSystemComponent windParticle;
var SoundCue mWindCue;

var GGRadialForceActor magicForceComponent;
var ParticleSystem magnetParticleTemplate;
var ParticleSystemComponent magnetParticle;
var ParticleSystem magnetRepulsiveParticleTemplate;
var ParticleSystemComponent magnetRepulsiveParticle;
var SoundCue mMagnetCue;

var ParticleSystem mindParticleTemplate;
var ParticleSystemComponent mindParticle;
var SkeletalMeshComponent mindMagicComp1;
var SkeletalMeshComponent mindMagicComp2;
var SkeletalMeshComponent mindMagicComp3;
var instanced GGRB_Handle grabber;

var ParticleSystem lifeParticleTemplate;
var ParticleSystemComponent lifeParticle;
var ParticleSystem lifeExplosionParticleTemplate;
var SoundCue lifeExplosionSound;
var SoundCue mLifeCue;

var ParticleSystem deathParticleTemplate;
var ParticleSystemComponent deathParticle;
var ParticleSystem deathExplosionParticleTemplate;
var SoundCue deathExplosionSound;
var SoundCue mDeathCue;

var ParticleSystem earthParticleTemplate;
var ParticleSystemComponent earthParticle;
var ParticleSystemComponent earthSmallParticle;
var Meteor earthBoulder;
var SoundCue mEarthCue;

var ElectrifiedActor elecComp;
var ParticleSystem elecExplosionParticleTemplate;
var SoundCue elecExplosionSound;
var ParticleSystem elecParticleTemplate;
var ParticleSystemComponent elecParticle;

var ParticleSystem geyserParticleTemplate;
var ParticleSystemComponent geyserParticle;
var GGWaterJet mWaterJet;
var SoundCue mWaterJetCue;
var float waterForce;
var float mBaseWaterVelocity;
var float mGeyserRadius;
var float mGeyserForce;

var ParticleSystem iceParticleTemplate;
var ParticleSystemComponent iceParticle;
var ParticleSystem iceExplosionParticleTemplate;
var SoundCue iceExplosionSound;
var SoundCue mFreezeCue;

enum EMagicTypes
{
	M_Fire,
	M_Water,
	M_Wind,
	M_Magnet,
	M_Mind,
	M_Life,
	M_Death,
	M_Earth,
	M_Thunder,
	M_Ice,
	M_NbMagics
};

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	InitMagicBall(GGGoat(Owner));
}

function InitMagicBall(GGGoat wiz)
{
	magicParticle = WorldInfo.MyEmitterPool.SpawnEmitter(magicParticleTemplate, Location, Rotation + (rot(1, 0, 0)*180*DegToUnrRot), self);
	magicParticle.SetHidden(true);

	fireParticle = WorldInfo.MyEmitterPool.SpawnEmitter(fireParticleTemplate, Location, Rotation, self);
	fireParticle.SetHidden(true);

	windParticle = WorldInfo.MyEmitterPool.SpawnEmitter(windParticleTemplate, Location, Rotation, self);
	windParticle.SetHidden(true);
	magicForceComponent = Spawn( class'GGRadialForceActor' );
	magicForceComponent.SetBase(self);

	magnetParticle = WorldInfo.MyEmitterPool.SpawnEmitter(magnetParticleTemplate, Location, Rotation, self);
	magnetParticle.SetHidden(true);
	magnetRepulsiveParticle = WorldInfo.MyEmitterPool.SpawnEmitter(magnetRepulsiveParticleTemplate, Location, Rotation, self);
	magnetRepulsiveParticle.SetHidden(true);

	mindParticle = WorldInfo.MyEmitterPool.SpawnEmitter(mindParticleTemplate, Location, Rotation, self);
	mindParticle.SetHidden(true);
	mindMagicComp1.SetHidden(true);
	mindMagicComp2.SetHidden(true);
	mindMagicComp3.SetHidden(true);

	lifeParticle = WorldInfo.MyEmitterPool.SpawnEmitter(lifeParticleTemplate, Location, Rotation, self);
	lifeParticle.SetHidden(true);
	deathParticle = WorldInfo.MyEmitterPool.SpawnEmitter(deathParticleTemplate, Location, Rotation, self);
	deathParticle.SetHidden(true);

	earthParticle = WorldInfo.MyEmitterPool.SpawnEmitter(earthParticleTemplate, Location, Rotation + (rot(1, 0, 0)*90*DegToUnrRot), self);
	earthParticle.SetHidden(true);
	earthSmallParticle.SetHidden(true);

	elecParticle = WorldInfo.MyEmitterPool.SpawnEmitter(elecParticleTemplate, Location, Rotation + (rot(1, 0, 0)*90*DegToUnrRot), self);
	elecParticle.SetHidden(true);

	AttachComponent(mWaterJet);
	geyserParticle = WorldInfo.MyEmitterPool.SpawnEmitter(geyserParticleTemplate, Location, Rotation, self);
	geyserParticle.SetHidden(true);

	iceParticle = WorldInfo.MyEmitterPool.SpawnEmitter(iceParticleTemplate, Location, Rotation + (rot(-1, 0, 0)*90*DegToUnrRot), self);
	iceParticle.SetHidden(true);

	wizard=wiz;
	myComp=WizardGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'WizardGoatComponent', wizard.mCachedSlotNr));
	SetMagicType(0);
}

function SetMagicType(int mType)
{
	local int desiredMType;
	local float multiplier;
	local bool newType;

	desiredMType=mType<M_NbMagics?mType:0;

	newType=desiredMType!=currentMType;

	DisableAllEffects();

	if(newType && isMagicActive)
	{
		PlaySound(magicSound);

		switch(desiredMType)
		{
			case M_Fire:
				WorldInfo.Game.Broadcast(self, "Fire Magic");
				break;
			case M_Wind:
				WorldInfo.Game.Broadcast(self, "Wind Magic");
				break;
			case M_Magnet:
				WorldInfo.Game.Broadcast(self, "Magnet Magic");
				break;
			case M_Mind:
				WorldInfo.Game.Broadcast(self, "Mind Magic");
				break;
			case M_Life:
				WorldInfo.Game.Broadcast(self, "Life Magic");
				break;
			case M_Death:
				WorldInfo.Game.Broadcast(self, "Death Magic");
				break;
			case M_Earth:
				WorldInfo.Game.Broadcast(self, "Earth Magic");
				break;
			case M_Thunder:
				WorldInfo.Game.Broadcast(self, "Thunder Magic");
				break;
			case M_Water:
				WorldInfo.Game.Broadcast(self, "Water Magic");
				break;
			case M_Ice:
				WorldInfo.Game.Broadcast(self, "Ice Magic");
				break;
		}

		if(currentMType == M_Mind)
		{
			DropActor();
		}
	}

	if(!isMagicActive)
	{
		magicParticle.SetHidden(false);
		DropActor();
	}
	else
	{
		currentMType=desiredMType;//Needed here for TryToBurn/TryToElec to work
		switch(currentMType)
		{
			case M_Fire:
				fireParticle.SetHidden(false);
				burningComp=myComp.myMut.TryToBurn(self, true);//WorldInfo.Game.Broadcast(self, "TryToBurn 0");
				break;
			case M_Wind:
				windParticle.SetHidden(false);
				multiplier=1;
				if(effect)
				{
					multiplier=-1;
				}
				magicForceComponent.ForceRadius = magicRadius;
				magicForceComponent.ForceStrength = -1000;
				magicForceComponent.SwirlStrength = 500*multiplier;
				magicForceComponent.SpinTorque = 500*multiplier;
				magicForceComponent.bForceActive=true;
				SetGlobalSound(mWindCue);
				break;
			case M_Magnet:
				multiplier=1;
				if(effect)
				{
					multiplier=-1;
					magnetParticle.SetHidden(false);
				}
				else
				{
					magnetRepulsiveParticle.SetHidden(false);
				}
				magicForceComponent.ForceRadius = magicRadius;
				magicForceComponent.ForceStrength = 1000*multiplier;
				magicForceComponent.SwirlStrength = 0;
				magicForceComponent.SpinTorque = 0;
				magicForceComponent.bForceActive=true;
				SetGlobalSound(mMagnetCue);
				break;
			case M_Mind:
				mindMagicComp1.SetHidden(false);
				mindMagicComp2.SetHidden(false);
				mindMagicComp3.SetHidden(false);
				if(grabbedItem == none)
				{
					mindParticle.SetHidden(false);
				}
				break;
			case M_Life:
				lifeParticle.SetHidden(false);
				SetGlobalSound(mLifeCue);
				break;
			case M_Death:
				deathParticle.SetHidden(false);
				SetGlobalSound(mDeathCue);
				break;
			case M_Earth:
				if(effect)
				{
					earthParticle.SetHidden(false);
				}
				else
				{
					earthSmallParticle.SetHidden(false);
				}
				SetGlobalSound(mEarthCue);
				break;
			case M_Thunder:
				elecParticle.SetHidden(false);
				elecComp=myComp.myMut.TryToElec(self, true);
				break;
			case M_Water:
				if(effect)
				{
					mWaterJet.EnableWaterJet();
				}
				else
				{
					geyserParticle.SetHidden(false);
				}
				SetGlobalSound(mWaterJetCue);
				break;
			case M_Ice:
				iceParticle.SetHidden(false);
				SetGlobalSound(mFreezeCue);
				break;
		}
	}
}

function DisableAllEffects()
{
	SetGlobalSound(none);
	magicParticle.SetHidden(true);
	burningComp.DisableMagic();
	fireParticle.SetHidden(true);
	windParticle.SetHidden(true);
	magnetParticle.SetHidden(true);
	magnetRepulsiveParticle.SetHidden(true);
	magicForceComponent.bForceActive=false;
	mindParticle.SetHidden(true);
	mindMagicComp1.SetHidden(true);
	mindMagicComp2.SetHidden(true);
	mindMagicComp3.SetHidden(true);
	lifeParticle.SetHidden(true);
	deathParticle.SetHidden(true);
	earthParticle.SetHidden(true);
	earthSmallParticle.SetHidden(true);
	elecComp.DisableMagic();
	elecParticle.SetHidden(true);
	if(mWaterJet.mIsEnabled) mWaterJet.DisableWaterJet();
	geyserParticle.SetHidden(true);
	iceParticle.SetHidden(true);
}

function ActivateMagic()
{
	isMagicActive=!isMagicActive;
	SetMagicType(currentMType);
	if(currentMType == M_Earth)
	{
		if(isMagicActive)
		{
			CreateMeteor();
		}
		else
		{
			DestroyMeteor();
		}
	}
}

function SwitchMagicEffect()
{
	effect=!effect;

	if(isMagicActive)
	{
		if(currentMType == M_Fire || currentMType == M_Thunder || currentMType == M_Life || currentMType == M_Death || currentMType == M_Ice)
		{
			Explode();
		}

		if(currentMType == M_Mind)
		{
			if(grabbedItem != none)
			{
				DropActor();
			}
			else
			{
				GrabActor();
			}
		}
	}

	SetMagicType(currentMType);
}

function bool CanBeOnFire()
{
	return isMagicActive && currentMType == M_Fire;
}

function bool CanBeElectrified()
{
	return isMagicActive && currentMType == M_Thunder;
}

function Explode()
{
	local Actor hitActor;
	local ParticleSystem exPST;
	local SoundCue exSound;
	local ParticleSystemComponent explosionEffect;

	if(currentMType == M_Fire)
	{
		exPST=explosionParticleTemplate;
		exSound=explosionSound;
	}
	else if(currentMType == M_Thunder)
	{
		exPST=elecExplosionParticleTemplate;
		exSound=elecExplosionSound;
	}
	else if(currentMType == M_Life)
	{
		exPST=lifeExplosionParticleTemplate;
		exSound=lifeExplosionSound;
	}
	else if(currentMType == M_Death)
	{
		exPST=deathExplosionParticleTemplate;
		exSound=deathExplosionSound;
	}
	else if(currentMType == M_Ice)
	{
		exPST=iceExplosionParticleTemplate;
		exSound=iceExplosionSound;
	}
	else
	{
		return;
	}
	PlaySound(exSound, true, true);

	explosionEffect = WorldInfo.MyEmitterPool.SpawnEmitter(exPST, Location);
	if(currentMType == M_Life || currentMType == M_Death)
	{
		explosionEffect.SetScale( 5.f );
	}

	foreach CollidingActors( class'Actor', hitActor, magicRadius, Location)
	{
		if(currentMType == M_Fire)
		{
			myComp.myMut.TryToBurn(hitActor);//WorldInfo.Game.Broadcast(self, "TryToBurn 1");
		}
		else if(currentMType == M_Thunder)
		{
			myComp.myMut.TryToElec(hitActor);
		}
		else if(currentMType == M_Life)
		{
			HealActor(hitActor);
		}
		else if(currentMType == M_Death)
		{
			KillActor(hitActor);
		}
		else if(currentMType == M_Ice)
		{
			myComp.myMut.TryToFreeze(hitActor);
		}
	}
}

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	//Update global sound
	if( mGlobalAC == none )
	{
		mGlobalAC = CreateAudioComponent( magicSound,,, true );
		SetGlobalSound(none);
	}
	mGlobalAC.VolumeMultiplier = EvalInterpCurveFloat(mGlobalVolume, VSize(Location - GetPawnPosition(wizard)));

	//Update self rotation
	UpdateRotation();

	//Update grabber location
	grabber.SetLocation(Location);

	//Fix Touch not working on ragdolls
	TouchActors();

	//Control meteor
	if(currentMType == M_Earth && isMagicActive && effect)
	{
		ControlMeteor();
	}

	//Do water stream effect
	if(currentMType == M_Water && isMagicActive)
	{
		UpdateWaterJetAim();
	}
}

function SetGlobalSound(SoundCue newSound)
{
	if(mGlobalAC.SoundCue == newSound)
		return;

	if(mGlobalAC.IsPlaying())
	{
		mGlobalAC.Stop();
	}
	mGlobalAC.SoundCue=newSound;
	if(mGlobalAC.SoundCue != none)
	{
		mGlobalAC.Play();
	}
}

function TouchActors()
{
	local Actor act;
	local float radius;

	radius=CylinderComponent(CollisionComponent).CollisionRadius;
	foreach OverlappingActors( class'Actor', act, radius * sqrt(2), Location)
	{
		Touched(act);
	}
}

function Touched(Actor act)
{
	if(act == self)
		return;

	if(isMagicActive)
	{
		if(currentMType == M_Life)
		{
			HealActor(act, true);
		}
		else if(currentMType == M_Death)
		{
			KillActor(act);
		}
		else if(currentMType == M_Ice)
		{
			myComp.myMut.TryToFreeze(act);
		}
		else if(currentMType == M_Fire)
		{
			myComp.myMut.TryToBurn(act);//WorldInfo.Game.Broadcast(self, "TryToBurn 2");
		}
		else if(currentMType == M_Thunder)
		{
			myComp.myMut.TryToElec(act);
		}
	}
}

function UpdateRotation()
{
	local vector dir;

	dir=Location - wizard.Location;
	dir.Z=0;
	SetRotation(Rotator(Normal(dir)));
}

function HealActor(Actor act, optional bool bringToLife)
{
	local GGNpc npc;
	local GGNpcMMOAbstract MMONpc;
	local GGNpcZombieGameModeAbstract zombieNpc;
	local GGKActor kAct;
	local GGAIController AIC;
	local Controller newCont;
	local class<Controller> contClass;
	local LivingActor la;

	npc = GGNpc(act);
	MMONpc = GGNpcMMOAbstract(act);
	zombieNpc = GGNpcZombieGameModeAbstract(act);
	if(npc != none && npc.mIsRagdoll)
	{
		AIC=GGAIController(npc.Controller);
		npc.EnableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
		npc.mTimesKnockedByGoat=0;
		npc.mTimesKnockedByGoatStayDownLimit=max(3, npc.default.mTimesKnockedByGoatStayDownLimit);
		if(MMONpc != none)
		{
			MMONpc.mHealth=max(MMONpc.default.mHealthMax, MMONpc.default.mHealth);
			MMONpc.LifeSpan=MMONpc.default.LifeSpan;
			MMONpc.mNameTagColor=MMONpc.default.mNameTagColor;
		}
		if(zombieNpc != none)
		{
			zombieNpc.mHealth=zombieNpc.default.mHealthMax;
			zombieNpc.mIsPendingDeath=false;
		}

		if(AIC == none)
		{
			contClass=npc.ControllerClass;
			if(contClass == none)
			{
				contClass=class'GGAIController';
			}
			newCont=Spawn(contClass);
			newCont.Possess(npc, false);
			npc.Controller=newCont;
			AIC=GGAIController(newCont);
		}
		AIC.StandUp();
	}

	kAct = GGKActor(act);
	if(bringToLife && kAct != none)
	{
		la=myComp.myMut.TryToMakeLive(kAct);
		if(la != none) la.AssignMaster(wizard);
	}
}

function KillActor(Actor act)
{
	local GGNpc npc;
	local GGNpcMMOAbstract MMONpc;
	local GGNpcZombieGameModeAbstract zombieNpc;

	npc = GGNpc(act);
	MMONpc = GGNpcMMOAbstract(act);
	zombieNpc = GGNpcZombieGameModeAbstract(act);
	if(npc != none)
	{
		npc.DisableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
		npc.mTimesKnockedByGoat=0;
		npc.mTimesKnockedByGoatStayDownLimit=0;
		npc.SetRagdoll(true);
		if(MMONpc != none)
		{
			MMONpc.mHealth=1;
			MMONpc.TakeDamage(MMONpc.mHealth, none, MMONpc.Location, vect(0, 0, 0), class'GGDamageType',, wizard);
			if(MMONpc.mHealth > 0)
			{
				MMONpc.mHealth=0;
				MMONpc.TakeDamage(MMONpc.mHealth, none, MMONpc.Location, vect(0, 0, 0), class'GGDamageType');
			}
		}
		if(zombieNpc != none)
		{
			zombieNpc.TakeDamage(zombieNpc.mHealth, none, zombieNpc.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode');
		}
	}

	myComp.myMut.StopLiving(act);
}

function Actor FindClosestActor()
{
	local Actor foundActor, hitActor;
	local float grabRange;
	local vector grabLocation;

	grabLocation=Location;
	grabRange=10;

	foundActor = none;

	foreach OverlappingActors( class'Actor', hitActor, grabRange, grabLocation)
	{
		if( GGGrabbableActorInterface( hitActor ) != none && hitActor != self )
		{
			if( foundActor == none || VSizeSq( hitActor.Location - grabLocation ) < VSizeSq( foundActor.Location - grabLocation ) )
			{
				foundActor = hitActor;
			}
		}
	}

	return foundActor;
}

/**
 * Finds an item we can grab.

 *
 * @param grabLocation - Location we are grabbing at.
 * @param grabRange - How far we can reach from grab location.
 *
 * @return - An actor we can grab.
 */
function GrabActor()
{
	local Actor item;
	local name boneName;
	local PrimitiveComponent grabComponent;
	local GGGrabbableActorInterface grabbableInterface;

	//Try to grab the closest actor
	item=FindClosestActor();
	grabbableInterface = GGGrabbableActorInterface( item );

	if( grabbableInterface == none )
	{
		return;
	}

	boneName = grabbableInterface.GetGrabInfo( Location );

	if( grabbableInterface.CanBeGrabbed( self, boneName ) )
	{
		grabComponent = grabbableInterface.GetGrabbableComponent();

		grabbableInterface.OnGrabbed( self );
	}
	else
	{
		return;
	}

	// Grab the item.
	grabber.GrabComponent( grabComponent, boneName, Location, false );
	grabbedItem = item;

	if(GGNpc(grabbedItem) != none)
	{
		GGNpc(grabbedItem).DisableStandUp( class'GGNpc'.const.SOURCE_FISHINGROD );
	}
}

function DropActor()
{
	if( grabbedItem != none )
	{
		grabber.ReleaseComponent();
		GGGrabbableActorInterface( grabbedItem ).onDropped( self );
		if(GGNpc(grabbedItem) != none)
		{
			GGNpc(grabbedItem).EnableStandUp( class'GGNpc'.const.SOURCE_FISHINGROD );
		}
		grabbedItem = none;
	}
}

function CreateMeteor()
{
  local vector spawnLoc;

  if(earthBoulder == none)
  {
		spawnLoc=Location;
		spawnLoc.x+=Rand(2001)-1000;
		spawnLoc.y+=Rand(2001)-1000;
		spawnLoc.z+=5000;

		earthBoulder = Spawn(class'Meteor', self, , spawnLoc);
		earthBoulder.myMesh.AddImpulse( (Location - earthBoulder.Location) * 1000.f );
  }
}

function ControlMeteor()
{
	local vector direction;
	local float distance;
	local float force;

	if(earthBoulder == none)
	{
		return;
	}

	direction = Location - earthBoulder.Location;
	distance = VSize(direction);

	//WorldInfo.Game.Broadcast(self, "distance(" $ distance $ ")");

	if(distance > 200)
	{
		force=Max((1000-VSize(earthBoulder.Velocity))*100, 10000);
		earthBoulder.ApplyImpulse( direction,  force,  earthBoulder.Location);
	}
	else
	{
		force=100*VSize(earthBoulder.Velocity);
		earthBoulder.ApplyImpulse( - earthBoulder.Velocity,  force,  earthBoulder.Location);
	}
}

function DestroyMeteor()
{
	earthBoulder.Destroy();
	earthBoulder=none;
}

/**
 * Updates the aim, velocity, range of the water jet.
 */
function UpdateWaterJetAim()
{
	local Actor pushedActor;
	local GGPawn pushedPawn;
	local PrimitiveComponent pushedComp;
	local vector pushedPos, POI, Extent, A, B, vel;
	local GJKResult res;
	local float dist;

	mWaterJet.mWaterVelocity = mBaseWaterVelocity;
	mWaterJet.mShootDirection = Normal2D(Location - GetPawnPosition(wizard));
	//do geyser water force
	if(!effect)
	{
		foreach OverlappingActors(class'Actor', pushedActor, magicRadius, Location)
		{
		    pushedPawn=GGPawn(pushedActor);
		    pushedPos=pushedPawn!=none?GetPawnPosition(pushedPawn):pushedActor.Location;
		    pushedComp=pushedPawn!=none?pushedPawn.mesh:pushedActor.CollisionComponent;
		    dist=VSize2D(pushedPos - Location);//for ragdolls
			POI=Location;
			Extent=vect(1, 1, 0) * mGeyserRadius + vect(0, 0, 1) * magicRadius;
			res=pushedActor.CollisionComponent.ClosestPointOnComponentToPoint(POI, Extent, A, B);
			if(pushedPos.Z < Location.Z || (dist > mGeyserRadius && (res == GJK_Fail || VSizeSq(A - B) > 0.01f)))//Only take actors in a cylinder
				continue;

			if(pushedPawn != none)
			{
				if(!pushedPawn.mIsRagdoll)
				{
					pushedPawn.SetPhysics(PHYS_Falling);
					pushedPawn.Velocity.Z=mGeyserForce;
					pushedComp=none;//No more push in this situation
				}
			}

			if(pushedComp != none)
			{
				vel=pushedComp.GetRBLinearVelocity();
				vel.Z=mGeyserForce;
				pushedComp.SetRBLinearVelocity(vel);
			}
			//To stop fire
			myComp.myMut.ProcessOnTakeDamage(pushedActor, none, 0, class'GGDamageTypeWaterJetWater', vect(0, 0, 0));
		}
	}
}

function vector GetPawnPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

DefaultProperties
{
	isMagicActive=true

	bCanBeDamaged=false
	bBlockActors=false
	bCollideActors=true
	Physics=PHYS_None
	CollisionType=COLLIDE_TouchAll

	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollideActors=true
		CollisionRadius=20.f
		CollisionHeight=20.f
		bAlwaysRenderIfSelected=true
	End Object
	Components.Add(CollisionCylinder)
	CollisionComponent=CollisionCylinder

	bCallRigidBodyWakeEvents=true

	mGlobalVolume=(Points=((InVal=0.0,OutVal=1.0),(InVal=600.0,OutVal=0.5),(InVal=1200.0,OutVal=0.0)))

	magicParticleTemplate=ParticleSystem'jetPack.Effects.JetThrust'
	magicSound=SoundCue'Goat_Sounds.Cue.Effect_Goat_MagicMushroom_cue'

	explosionParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Explosion_Huge_01'
	explosionSound=SoundCue'Goat_Sounds.Cue.Explosion_Car_Cue'
	fireParticleTemplate=ParticleSystem'MMO_Effects.Effects.Effects_FireBall_01'

	windParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Tornado_01'
	mWindCue=SoundCue'Zombie_Goat_Sounds.HangGlideGoat.HangGlideGoat_Wind_Cue'

	magnetParticleTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'
	magnetRepulsiveParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Skid_01'
	mMagnetCue=SoundCue'Heist_Audio.Cue.AMB_TheMoon_Drone_Loop_Cue'

	mindParticleTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Glow_01'
	Begin Object class=SkeletalMeshComponent Name=haloMesh1
		SkeletalMesh=SkeletalMesh'goat.mesh.Gloria_01'
	End Object
	mindMagicComp1=haloMesh1
	Components.Add(haloMesh1)
	Begin Object class=SkeletalMeshComponent Name=haloMesh2
		SkeletalMesh=SkeletalMesh'goat.Mesh.Gloria_01'
		Rotation=(Pitch=16384, Yaw=0, Roll=0)
	End Object
	mindMagicComp2=haloMesh2
	Components.Add(haloMesh2)
	Begin Object class=SkeletalMeshComponent Name=haloMesh3
		SkeletalMesh=SkeletalMesh'goat.Mesh.Gloria_01'
		Rotation=(Pitch=0, Yaw=0, Roll=16384)
	End Object
	mindMagicComp3=haloMesh3
	Components.Add(haloMesh3)
	Begin Object class=GGRB_Handle name=ObjectGrabber
		LinearDamping=1.0
		LinearStiffness=1000000.0
		AngularDamping=1.0
		AngularStiffness=1000000.0
	End Object
	grabber=ObjectGrabber

	lifeParticleTemplate=ParticleSystem'Zombie_Particles.Particles.Voodoo_Trail_ParticleSystem'
	lifeExplosionParticleTemplate=ParticleSystem'Zombie_Particles.Particles.Health_Pickup_PS'
	lifeExplosionSound=SoundCue'Goat_Sounds.Cue.HolyGoat_Cue'
	mLifeCue=SoundCue'MMO_SFX_SOUND.Cue.SFX_Twistram_Teleport_Loop_Cue'

	deathParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_RepulsiveGoat_01'
	deathExplosionParticleTemplate=ParticleSystem'Zombie_Particles.Particles.ZombieTransitionParticleSystem_2'
	deathExplosionSound=SoundCue'Zombie_NPC_Sound.Death.Zombie_Death_Cue'
	mDeathCue=SoundCue'Goat_Sound_Ambience_01.Cue.SummoningCircle_Cue'

	earthParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Skid_Car_01'
	Begin Object class=ParticleSystemComponent name=PCS1
		Template=ParticleSystem'Goat_Effects.Effects.Effects_Skid_Car_01'
		Scale=0.5f
		bAutoActivate=true
		Rotation=(Pitch=16384, Yaw=0, Roll=0)
	End Object
	earthSmallParticle=PCS1
	Components.Add(PCS1)
	mEarthCue=SoundCue'Heist_Audio.Cue.Ambient_Desert_Wind_Strong_Stereo_Cue'

	elecExplosionParticleTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Ragdoll_Explosion_01'
	elecExplosionSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Excalibur_Explosion_Cue'
	elecParticleTemplate=ParticleSystem'MMO_Effects.Effects.Effects_Ragdoll_Projectile_01'

	geyserParticleTemplate=ParticleSystem'Whale.Effects.Water'
	mBaseWaterVelocity=2000.f//15000.f
	//waterForce=100.f
	//mWaterCollisionRange=30.f
	mGeyserRadius=50.f
	mGeyserForce=1000.f
	Begin Object class=GGWaterJet name=ObjectWaterJet
		mWaterNodeInterval=0.10f
		mWaterVelocity=1000
		mWaterNodeLifeSpan=3.0
		mWaterDamageType=class'GGDamageTypeWaterJetWater'
		mWaterForceTransfer=5.5f
	End Object
	mWaterJet=ObjectWaterJet
	mWaterJetCue=SoundCue'Heist_Audio.Cue.SFX_Camel_Spray_Medium_Cue'

	iceParticleTemplate=ParticleSystem'Zombie_Particles.Particles.Crystal_Breath_ParticleSystem'
	iceExplosionParticleTemplate=ParticleSystem'Zombie_Particles.Particles.Antiquer_Explosion_PS'
	iceExplosionSound=SoundCue'MMO_NPC_SND.Cue.NPC_Old_Goat_Idle_Breath'
	mFreezeCue=SoundCue'Zombie_Goat_Sounds.HeisenGoat.HeisenGoat_Breath_Loop_Cue'

	magicRadius=600.f
}