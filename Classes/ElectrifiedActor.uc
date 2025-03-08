class ElectrifiedActor extends MagicActor;

//var ParticleSystem elecParticleTemplate;
var ParticleSystemComponent elecParticle;
var AudioComponent mElecAC;
var SoundCUe mElecSound;
var Actor electrifiedActor;
var GGPawn electrifiedPawn;
var bool elecForever;
var float spasmForce;

static function bool IsValidActor(Actor actorToElec)
{
	if(!super.IsValidActor(actorToElec))
		return false;

	return (MagicBallActor(actorToElec) != none && MagicBallActor(actorToElec).CanBeElectrified())
		|| GGGrabbableActorInterface(actorToElec) != none
		|| (GGApexDestructibleActor(actorToElec) != none && !GGApexDestructibleActor(actorToElec).mIsFractured);
}

function Actor GetMagicActor()
{
	return electrifiedActor;
}

function EnableMagic(Actor target, optional bool enableForever)
{
	local bool isAttached;
	//WorldInfo.Game.Broadcast(self, "elecIt(" $ target $ ")");
	if(electrifiedActor == none)
	{
		elecForever=enableForever;
		electrifiedActor=target;
		electrifiedPawn=GGPawn(electrifiedActor);
		SetLocation(electrifiedActor.Location);
		SetBase(electrifiedActor);

		//WorldInfo.Game.Broadcast(self, elecParticle $ " attached to " $ electrifiedActor);
		if(electrifiedPawn != none && electrifiedPawn.CustomTimeDilation != 0)
		{
			if(!IsZero(electrifiedPawn.mesh.GetBoneLocation('Spine_01')))
			{
				electrifiedPawn.mesh.AttachComponentToSocket(elecParticle, 'Spine_01');
				isAttached=true;
			}
			else if(!IsZero(electrifiedPawn.mesh.GetBoneLocation('Root')))
			{
				electrifiedPawn.mesh.AttachComponentToSocket(elecParticle, 'Root');
				isAttached=true;
			}
		}
		if(!isAttached)
		{
			AttachComponent(elecParticle);
		}
		elecParticle.ActivateSystem(true);
	}

	if(electrifiedPawn != none)
	{
		electrifiedPawn.SetDodgyRagdoll(true);
		electrifiedPawn.SetRagdoll(true);

	}
	if(GGNpc(electrifiedPawn) != none)
	{
		GGNpc(electrifiedPawn).DisableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
	}
	ElectrifiedSpasm();

	if(mElecAC == none)
	{
		mElecAC = CreateAudioComponent( mElecSound, ,true );
	}
	if(mElecAC != none && !mElecAC.IsPlaying())
	{
		mElecAC.Play();
	}

	if(!elecForever && !myMut.IsTimerActive( NameOf( DisableMagic ), self ))
	{
		myMut.SetTimer( FRand() * 2.0f + 8.0f, false, NameOf( DisableMagic ), self);
	}
}

function DisableMagic(optional bool forceStop)
{
	//WorldInfo.Game.Broadcast(self, "Stopelec");
	if(electrifiedPawn != none)
	{
		electrifiedPawn.SetDodgyRagdoll(false);

	}
	if(GGNpc(electrifiedPawn) != none)
	{
		GGNpc(electrifiedPawn).EnableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
	}

	if( myMut.IsTimerActive( NameOf( DisableMagic ), self ) )
	{
		myMut.ClearTimer( NameOf( DisableMagic ), self );
	}
	if( IsTimerActive( NameOf( ElectrifiedSpasm ) ) )
	{
		ClearTimer( NameOf( ElectrifiedSpasm ) );
	}

	if( elecParticle != none )
	{
		elecParticle.DetachFromAny();
		elecParticle.DeactivateSystem();
		elecParticle.KillParticlesForced();
	}
	if(mElecAC != none && mElecAC.IsPlaying())
	{
		mElecAC.Stop();
	}

	Destroy();
}

function ElectrifiedSpasm()
{
	local rotator randRot;
	local vector dir;
	local PrimitiveComponent elecComp;

	if(GGPawn(electrifiedActor) != none)
	{
		elecComp=GGPawn(electrifiedActor).mesh;
	}
	else
	{
		elecComp=electrifiedActor.CollisionComponent;
	}

	randRot.Pitch=RandRange(0.f, 65536.f);
	randRot.Yaw=RandRange(0.f, 65536.f);
	randRot.Roll=RandRange(0.f, 65536.f);
	dir=Normal(vector(randRot));
	elecComp.SetRBLinearVelocity(elecComp.GetRBLinearVelocity() + dir * spasmForce);

	SetTimer( 0.25f, true, nameof( ElectrifiedSpasm ) );
}

DefaultProperties
{
	mElecSound=SoundCue'Zombie_Sounds.ZombieGameMode.SFX_Boat_Electricity_Cue'

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
        Template=ParticleSystem'MMO_Effects.Effects.Effects_Electricity_01'
		bAutoActivate=true
		bResetOnDetach=true
	End Object
	elecParticle=ParticleSystemComponent0

	spasmForce=200.f
}