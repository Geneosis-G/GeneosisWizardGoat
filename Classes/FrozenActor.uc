class FrozenActor extends MagicActor;

var Actor frozenActor;
var GGNpc frozenNpc;
var GGNpcZombieGameModeAbstract frozenZGMNpc;
var SoundCue freezeSound;
var SoundCue breakSound;

var int mApexActorIndex;
var array<GGApexDestructibleActor> mApexActors;
var int mAccumulatedFrozenDamage;
var GGApexDestructibleActor mSpawnedApexActor;
var MaterialInstanceConstant mMaterialInstanceConstant;
var MaterialInterface mFrozenMaterial;

var vector actLocation;
var rotator actRotation;

static function bool IsValidActor(Actor actorToFreeze)
{
	if(!super.IsValidActor(actorToFreeze))
		return false;

	return (GGGrabbableActorInterface(actorToFreeze) != none
		  && GGGoat(actorToFreeze) == none)
		|| (GGApexDestructibleActor(actorToFreeze) != none
		  && (GGApexDestructibleActor(actorToFreeze).StaticDestructibleComponent.GetMaterial(0) != default.mFrozenMaterial
		    || !GGApexDestructibleActor(actorToFreeze).mIsFractured));
}

function Actor GetMagicActor()
{
	return frozenActor;
}

function EnableMagic(Actor target, optional bool enableForever)
{
	local MeshComponent meshComp;
	local int i;
	local GGScoreActorInterface scoreAct;
	local PhysicalMaterial physMat;
	//WorldInfo.Game.Broadcast(self, "FreezeIt(" $ target $ ")");
	if(target == none)
		return;

	if(frozenActor == none)
	{
		frozenActor=target;
		frozenNpc=GGNpc(frozenActor);
		frozenZGMNpc=GGNpcZombieGameModeAbstract(frozenActor);
		SetLocation(frozenActor.Location);
		SetBase(frozenActor);
		//To stop fire
		myMut.ProcessOnTakeDamage(frozenActor, none, 0, class'GGDamageTypeWaterJetWater', vect(0, 0, 0));
	}
	else
	{
		return;
	}

	PlaySound( freezeSound, false,,, Location );
	if(frozenNpc != none)
	{
		//Force unragdoll instantly
		if(frozenNpc.mIsRagdoll)
		{
			frozenNpc.Velocity=vect(0, 0, 0);
			frozenNpc.StandUp();
			frozenNpc.mesh.PhysicsWeight=0;
			frozenNpc.TerminateRagdoll(0.f);
		}
		frozenNpc.mIsRagdollAllowed = false;

		if( frozenNpc.CustomTimeDilation > 0 )
		{
			frozenNpc.mPreviousCustomTime = frozenNpc.CustomTimeDilation;
		}

		meshComp=frozenNpc.mesh;
		frozenNpc.GotoState( 'FrozenState' );
		frozenNpc.CustomTimeDilation = 0;

		// Determine Apex Archetype
		if(IsHuman(frozenNpc))
		{
			if(frozenNpc.mVoiceIdentity == VI_FEMALE)
			{
				mApexActorIndex = 2;// Girl
			}
			else
			{
				mApexActorIndex = 1;// Man
			}
		}
		else
		{
			mApexActorIndex = 3;// Goat
		}
	}
	else
	{
		meshComp=MeshComponent(frozenActor.CollisionComponent);
		frozenActor.SetPhysics(PHYS_None);
		actLocation=frozenActor.Location;
		actRotation=frozenActor.Rotation;
	}
	//Backup phys mat
	scoreAct=GGScoreActorInterface(frozenActor);
	if(scoreAct != none)
	{
		physMat=scoreAct.GetPhysMat();
	}
	//Frozen material
	for(i=0 ; i<meshComp.GetNumElements() ; i++)
	{
		meshComp.SetMaterial(i, mFrozenMaterial);
	}
	//Make apex frozen too
	if(GGKactor(frozenActor) != none && GGKactor(frozenActor).mApexActor != none)
	{
		for(i=0 ; i<GGKactor(frozenActor).mApexActor.StaticDestructibleComponent.GetNumElements() ; i++)
		{
			GGKactor(frozenActor).mApexActor.StaticDestructibleComponent.SetMaterial(i, mFrozenMaterial);
		}
	}
	//Restore phys mat
	if(physMat != none)
	{
		meshComp.SetPhysMaterialOverride(physMat);
	}
}

function DisableMagic(optional bool forceStop)
{
	Destroy();
}

function bool IsHuman(GGPawn gpawn)
{
	local GGAIControllerMMO AIMMO;

	if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualGirl_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "CasualMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SportyMan_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "HeistNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "Explorer_Physics") != INDEX_NONE)
	{
		return true;
	}
	else if(InStr(string(gpawn.Mesh.PhysicsAsset), "SpaceNPC_Physics") != INDEX_NONE)
	{
		return true;
	}
	AIMMO=GGAIControllerMMO(gpawn.Controller);
	if(AIMMO == none)
	{
		return false;
	}
	else
	{
		return AIMMO.PawnIsHuman();
	}
}

function BreakIce( int damageAmount, class< DamageType > damageType, vector momentum, Actor damageCauser)
{
	local GGGoat goat;
	local bool shouldBreakOnMomentum;
	local int i;
	local vector oldLoc;
	local GGPawn basedPawn, oldDriver;

	if( mApexActors[mApexActorIndex] == none )
		return;
	//WorldInfo.Game.Broadcast(self, "BreakIce=" $ frozenActor);
	mAccumulatedFrozenDamage += damageAmount;

	goat = GGGoat( damageCauser );

	shouldBreakOnMomentum = goat != none ? VSize( goat.Velocity ) > goat.mSprintSpeed && VSize( momentum ) >= mApexActors[mApexActorIndex].mTriggerFractureMomentum : VSize( momentum ) >= mApexActors[mApexActorIndex].mTriggerFractureMomentum;
	if( shouldBreakOnMomentum )
	{
		// Make sure the damn thing breaks. DamageThreshold seems unreliable.
		mAccumulatedFrozenDamage += mApexActors[mApexActorIndex].mDamageThreshold > 0 ? mApexActors[mApexActorIndex].mDamageThreshold * 10000000 : 10000000;
	}

	//WorldInfo.Game.Broadcast(self, "mSpawnedApexActor=" $ mSpawnedApexActor);
	//WorldInfo.Game.Broadcast(self, "mAccumulatedFrozenDamage=" $ mAccumulatedFrozenDamage);
	//WorldInfo.Game.Broadcast(self, "mApexActors[mApexActorIndex].mDamageThreshold=" $ mApexActors[mApexActorIndex].mDamageThreshold);
	if( mSpawnedApexActor == none && mAccumulatedFrozenDamage > mApexActors[mApexActorIndex].mDamageThreshold )
	{
		if(GGGameInfoZombie( WorldInfo.Game ) != none)
		{
			GGGameInfoZombie( WorldInfo.Game ).FrozenNPCWasShattered();
		}
		oldLoc=frozenActor.Location;
		if(GGApexDestructibleActor(frozenActor) != none)
		{
			if(!GGApexDestructibleActor(frozenActor).mIsFractured)
			{
				GGApexDestructibleActor(frozenActor).Fracture(0, none, frozenActor.Location, momentum, damageType,, damageCauser);
			}
			mSpawnedApexActor=GGApexDestructibleActor(frozenActor);
		}
		else if(GGKactor(frozenActor) != none && GGKactor(frozenActor).mApexActor != none && GGKactor(frozenActor).mSpawnedApexActor == none)
		{
   			GGKactor(frozenActor).mAccumulatedDamage=GGKactor(frozenActor).mApexActor.mDamageThreshold+1.f;
   			GGKactor(frozenActor).ConvertToApex(0, damageType, momentum, damageCauser);
   			mSpawnedApexActor=GGKactor(frozenActor).mSpawnedApexActor;
		}
		else
		{
			//Kick driver and passengers of vehicles
			if(GGSVehicle(frozenActor) != none)
			{
				oldDriver=GGPawn(GGSVehicle(frozenActor).Driver);
				GGSVehicle(frozenActor).KickOutDriver();
				oldDriver.SetRagdoll(true);
				for(i=0 ; i<GGSVehicle(frozenActor).mPassengerSeats.Length ; i++)
				{
					oldDriver=GGPawn(GGSVehicle(frozenActor).mPassengerSeats[i].VehiclePassengerSeat.Driver);
					GGSVehicle(frozenActor).mPassengerSeats[i].VehiclePassengerSeat.KickOutDriver();
					oldDriver.SetRagdoll(true);
				}
			}
			//Remove based pawns
			foreach frozenActor.BasedActors(class'GGPawn', basedPawn)
			{
				basedPawn.SetBase(none);
				basedPawn.SetPhysics(PHYS_Falling);
			}
			frozenActor.SetPhysics(PHYS_None);
			frozenActor.SetHidden(true);
			frozenActor.SetLocation(vect(0, 0, -1000));
			for( i = 0; i < frozenActor.Attached.Length; i++ )
			{
				if(GGGoat(frozenActor.Attached[i]) == none)
				{
					frozenActor.Attached[i].ShutDown();
					frozenActor.Attached[i].Destroy();
				}
			}
			frozenActor.Shutdown();
			frozenActor.Destroy();

			mSpawnedApexActor = Spawn( class'GGApexDestructibleActor',,, oldLoc,, mApexActors[mApexActorIndex], true);
			if(mApexActorIndex == 0)
			{
				for(i=0 ; i<mSpawnedApexActor.StaticDestructibleComponent.GetNumElements() ; i++)
				{
					mSpawnedApexActor.StaticDestructibleComponent.SetMaterial(i, mFrozenMaterial);
				}
				//Apex is named melon, this can't be changed
			}
			if(mSpawnedApexActor != none && !mSpawnedApexActor.mIsFractured)
			{
				mSpawnedApexActor.Fracture(0, none, mSpawnedApexActor.Location, momentum, damageType,, damageCauser);
			}
		}
		PlaySound(breakSound,,,, oldLoc);
		DisableMagic();
	}
}

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	//Force freeze actors
	if(frozenNpc == none && frozenActor.Physics != PHYS_None)
	{
		frozenActor.SetPhysics(PHYS_None);
		frozenActor.SetLocation(actLocation);
		frozenActor.SetRotation(actRotation);
	}
}

DefaultProperties
{
	mApexActors(0)=GGApexDestructibleActor'AArch.Food.arch.Melon_Big_Arch_01'
	mApexActors(1)=GGApexDestructibleActor'Zombie_Characters.Meshes.CasualMan_Frozen_01_Arch'
	mApexActors(2)=GGApexDestructibleActor'Zombie_Characters.Meshes.CasualGirl_Frozen_01_Arch'
	mApexActors(3)=GGApexDestructibleActor'Goat_Zombie.Mesh.Goat_Frozen_01_Arch'

	mFrozenMaterial=Material'Zombie_Characters.Materials.Frozen_Interior_Material'

	freezeSound=SoundCue'Zombie_Goat_Sounds.HeisenGoat.HeisenGoat_NPCFreeze_Cue'
	breakSound=SoundCue'Zombie_Goat_Sounds.HeisenGoat.Frozen_NPC_Break_Cue'
}