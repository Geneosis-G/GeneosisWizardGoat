class BurningActor extends MagicActor;

//var ParticleSystem fireParticleTemplate;
var ParticleSystemComponent fireParticle;
var AudioComponent mBurnAC;
var SoundCUe mBurnSound;
var Actor burningActor;
var GGPawn burningPawn;
var GGNPCMMOEnemy burningMMONpc;
var GGExplosiveActorAbstract expActor;
var bool burnForever;

static function bool IsValidActor(Actor actorToBurn)
{
	if(!super.IsValidActor(actorToBurn))
		return false;
	//actorToBurn.WorldInfo.Game.Broadcast(actorToBurn, "super.IsValidActor=true");
	return (MagicBallActor(actorToBurn) != none && MagicBallActor(actorToBurn).CanBeOnFire())
		|| GGGrabbableActorInterface(actorToBurn) != none
		|| (GGApexDestructibleActor(actorToBurn) != none && !GGApexDestructibleActor(actorToBurn).mIsFractured);
}

function Actor GetMagicActor()
{
	return burningActor;
}

function EnableMagic(Actor target, optional bool enableForever)
{
	local bool isAttached;
	//WorldInfo.Game.Broadcast(self, "EnableFireMagic=" $ target $ ", forever=" $ enableForever);
	if(burningActor == none)
	{
		burnForever=enableForever;
		burningActor=target;
		burningPawn=GGPawn(burningActor);
		burningMMONpc=GGNPCMMOEnemy(burningActor);
		expActor=GGExplosiveActorAbstract(burningActor);
		SetLocation(burningActor.Location);
		SetBase(burningActor);//WorldInfo.Game.Broadcast(self, "Physics=" $ Physics);

		//WorldInfo.Game.Broadcast(self, fireParticle $ " attached to " $ burningActor);
		if(burningPawn != none && burningPawn.CustomTimeDilation != 0)
		{
			if(!IsZero(burningPawn.mesh.GetBoneLocation('Spine_01')))
			{
				burningPawn.mesh.AttachComponentToSocket(fireParticle, 'Spine_01');
				isAttached=true;
			}
			else if(!IsZero(burningPawn.mesh.GetBoneLocation('Root')))
			{
				burningPawn.mesh.AttachComponentToSocket(fireParticle, 'Root');
				isAttached=true;
			}
		}
		if(!isAttached)
		{
			AttachComponent(fireParticle);
			//fireParticle = WorldInfo.MyEmitterPool.SpawnEmitter(fireParticleTemplate, burningActor.Location, burningActor.Rotation, burningActor);
		}
		fireParticle.ActivateSystem(true);

	}

	if(burningPawn != none)
	{
		if(GGAIController(burningPawn.Controller) != none && !GGAIController(burningPawn.Controller).IsInState('StartPanic'))
		{
			GGAIController( burningPawn.Controller ).Panic();
		}
 		burningPawn.mIsBurning = true;
		if(burningMMONpc != none)
		{
			if( !IsTimerActive( NameOf( BurningDoT ) ) )
			{
				BurningDoT();
			}
		}
	}

	if(mBurnAC == none)
	{
		mBurnAC = CreateAudioComponent( mBurnSound, ,true );
	}
	if(mBurnAC != none && !mBurnAC.IsPlaying())
	{
		mBurnAC.Play();
	}
	//Need to do it with another actor to handle the case where the pawn is frozen
	if( myMut.IsTimerActive( NameOf( DisableMagic ), self ) )
	{
		myMut.ClearTimer( NameOf( DisableMagic ), self );
	}
	if(!burnForever)
	{
		myMut.SetTimer( FRand() * 2.0f + 8.0f, false, NameOf( DisableMagic ), self);
	}
}

function DisableMagic(optional bool forceStop)
{
	local FrozenActor fa;
	//WorldInfo.Game.Broadcast(self, "DisableFireMagic=" $ burningActor $ ", forceStop=" $ forceStop);
	if(burningPawn != none)
	{
		burningPawn.mIsBurning = false;
	}
	if(!forceStop)
	{
		//Trigger explosions on explosive actors and break destructible actors
		if(burningPawn == none) burningActor.TakeDamage(1000000, none, burningActor.Location, vect(0, 0, 1), class'GGDamageTypeAbility',, self);
		//WorldInfo.Game.Broadcast(self, "BurningActorTakeDamage=" $ burningActor);
		fa=myMut.GetFrozenActor(burningActor);
		if(fa != none && fa.mSpawnedApexActor == none)//Make sure burning frozen actors are destroyed
		{
			//WorldInfo.Game.Broadcast(self, "ActorToBreak=" $ burningActor);
			myMut.ProcessOnTakeDamage(burningActor, none, 1000000, class'GGDamageTypeAbility', vect(0, 0, 1));
		}
	}

	if( myMut.IsTimerActive( NameOf( DisableMagic ), self ) )
	{
		myMut.ClearTimer( NameOf( DisableMagic ), self );
	}
	if( IsTimerActive( NameOf( BurningDoT ) ) )
	{
		ClearTimer( NameOf( BurningDoT ) );
	}

	if( fireParticle != none )
	{
		fireParticle.DetachFromAny();
		fireParticle.DeactivateSystem();
		fireParticle.KillParticlesForced();
	}
	if(mBurnAC != none && mBurnAC.IsPlaying())
	{
		mBurnAC.Stop();
	}

	Destroy();
}

function BurningDoT()
{
	burningMMONpc.TakeDoTDamage();
	SetTimer( 1.0f, true, nameof( BurningDoT ) );
}

DefaultProperties
{
	mBurnSound=SoundCue'Heist_Audio.Cue.SFX_Generic_Fire_Mono_Cue'

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
        Template=ParticleSystem'Goat_Effects.Effects.Effects_Fire_01'
		bAutoActivate=true
		bResetOnDetach=true
	End Object
	fireParticle=ParticleSystemComponent0
}