class WizardGoat extends GGMutator;

var float propagationRadius;

struct MagicActorsInfo
{
	var class<MagicActor> magicType;
	var array<MagicActor> magicActors;
};
var array<MagicActorsInfo> mMagicArray;

function MagicActor TryToAttachMagic(Actor actorToAttachTo, class<MagicActor> magicActorType, optional bool activateForever)
{
	local int magicIndex, i;
	local MagicActor magicAct;
	//WorldInfo.Game.Broadcast(self, "TryToAttachMagic=" $ actorToAttachTo $ ", type=" $ magicActorType $ ", forever=" $ activateForever $ " valid=" $ magicActorType.static.IsValidActor(actorToAttachTo));
	if(!magicActorType.static.IsValidActor(actorToAttachTo))
		return none;
	//Find or create magic array of given type
	magicIndex=mMagicArray.Find('magicType', magicActorType);
	if(magicIndex == INDEX_NONE)
	{
		mMagicArray.Add(1);
		magicIndex=mMagicArray.Length-1;
		mMagicArray[magicIndex].magicType=magicActorType;
	}
	//Find magic actor for the given actor
	for(i=0 ; i<mMagicArray[magicIndex].magicActors.Length ; i++)
	{
		if(mMagicArray[magicIndex].magicActors[i].GetMagicActor() == actorToAttachTo)
		{
			magicAct=mMagicArray[magicIndex].magicActors[i];
			break;
		}
	}
	//Create a new magic actor if needed
	if(magicAct == none)
	{
		magicAct = Spawn(magicActorType, self);
		mMagicArray[magicIndex].magicActors.AddItem(magicAct);
	}
	//Enable magic on actor
	magicAct.EnableMagic(actorToAttachTo, activateForever);

	return magicAct;
}

function MagicActor GetMagicActor(Actor actorToFind, class<MagicActor> magicActorType)
{
	local int magicIndex, i;

	if(!magicActorType.static.IsValidActor(actorToFind))
		return none;
	//Find magic array of given type
	magicIndex=mMagicArray.Find('magicType', magicActorType);
	if(magicIndex == INDEX_NONE)
		return none;

	for(i=0 ; i<mMagicArray[magicIndex].magicActors.Length ; i++)
	{
		if(mMagicArray[magicIndex].magicActors[i].GetMagicActor() == actorToFind)
		{
			return mMagicArray[magicIndex].magicActors[i];
		}
	}

	return none;
}

function OnMagicActorDestroyed(MagicActor magicActor)
{
	local int magicIndex;

	magicIndex=mMagicArray.Find('magicType', magicActor.class);
	if(magicIndex != INDEX_NONE)
	{
		mMagicArray[magicIndex].magicActors.RemoveItem(magicActor);
	}
}

function BurningActor TryToBurn(Actor actorToBurn, optional bool activateForever)
{
	return BurningActor(TryToAttachMagic(actorToBurn, class'BurningActor', activateForever));
}

function bool IsBurning(Actor target)
{
	return GetMagicActor(target, class'BurningActor') != none;
}

function ElectrifiedActor TryToElec(Actor actorToElec, optional bool activateForever)
{
	return ElectrifiedActor(TryToAttachMagic(actorToElec, class'ElectrifiedActor', activateForever));
}

function bool IsElectrified(Actor target)
{
	return GetMagicActor(target, class'ElectrifiedActor') != none;
}

function TryToFreeze(Actor actorToFreeze)
{
	TryToAttachMagic(actorToFreeze, class'FrozenActor');
}

function FrozenActor GetFrozenActor(Actor target)
{
	return FrozenActor(GetMagicActor(target, class'FrozenActor'));
}

function LivingActor TryToMakeLive(Actor actorToMakeLive)
{
	return LivingActor(TryToAttachMagic(actorToMakeLive, class'LivingActor'));
}

function StopLiving(Actor actorToKill)
{
	local MagicActor magicAct;

	if(!class'LivingActor'.static.IsValidActor(actorToKill))
		return;

	magicAct=GetMagicActor(actorToKill, class'LivingActor');
	if(magicAct != none)
	{
		magicAct.DisableMagic();
	}
}

/**
 * Called when a collision between two actors occur
 */
function OnCollision( Actor actor0, Actor actor1 )
{
	local Actor targetActor;

	targetActor=none;
	if(IsBurning(actor0))
	{
		targetActor=actor1;
	}
	else if(IsBurning(actor1))
	{
		targetActor=actor0;
	}

	if(targetActor != none && IsGoatCloseEnough(targetActor))
	{
		TryToBurn(targetActor);//WorldInfo.Game.Broadcast(self, "TryToBurn 3");
	}
	//WorldInfo.Game.Broadcast(self, actorOnFire $ " set " $ actorToBurn $ " on fire");

	targetActor=none;
	if(IsElectrified(actor0))
	{
		targetActor=actor1;
	}
	else if(IsElectrified(actor1))
	{
		targetActor=actor0;
	}

	if(targetActor != none && IsGoatCloseEnough(targetActor))
	{
		TryToElec(targetActor);
	}
}

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	super.OnTakeDamage(damagedActor, damageCauser, damage, dmgType, momentum);
	ProcessOnTakeDamage(damagedActor, damageCauser, damage, dmgType, momentum);
}

function ProcessOnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	local FrozenActor fa;
	local BurningActor ba;
	// Explosions spread fire
	if(dmgType == class'GGDamageTypeExplosiveActor' && IsBurning(damageCauser) && IsGoatCloseEnough(damagedActor))
	{
		TryToBurn(damagedActor);//WorldInfo.Game.Broadcast(self, "TryToBurn 4");
	}
	// Damages break ice
	//WorldInfo.Game.Broadcast(self, "NPC damaged : " $ damagedActor);
	fa = GetFrozenActor(damagedActor);
	if(fa != none)
	{
		//WorldInfo.Game.Broadcast(self, "frozen actor found : " $ fa);
		fa.BreakIce(damage, dmgType, momentum, damageCauser);
	}
	// Water stop fire
	if(dmgType == class'GGDamageTypeWaterJetWater' && IsBurning(damagedActor))
	{
		ba=TryToBurn(damagedActor);//WorldInfo.Game.Broadcast(self, "TryToBurn 5");
		if(ba != none)
		{
			ba.DisableMagic(true);
		}
	}
}
// Fix breaking interpactors and vehicles
function OnUseAbility( Actor actorInstigator, GGAbility abilityUsed, Actor actorVictim )
{
	local FrozenActor fa;

	super.OnUseAbility(actorInstigator, abilityUsed, actorVictim);
	// Attacks break ice
	if(abilityUsed.mDamage > 0)
	{
		fa = GetFrozenActor(actorVictim);
		if(fa != none)
		{
			//WorldInfo.Game.Broadcast(self, "frozen actor found : " $ fa);
			fa.BreakIce(abilityUsed.mDamage,
						abilityUsed.mDamageTypeClass,
						Normal2D(actorVictim.Location - actorInstigator.Location) * abilityUsed.mDamageTypeClass.default.mDamageImpulse,
						actorVictim);
		}
	}
}

function bool IsGoatCloseEnough(Actor center)
{
	local GGPlayerControllerGame pc;
	local vector dir;
	local float dist, minDist;

	if(center == none)
		return false;

	minDist=-1;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			dir=center.Location-pc.Pawn.Location;
			dir.Z=0;
			dist=VSize(dir);
			if(minDist == -1 || dist < minDist)
			{
				minDist=dist;
			}
		}
	}

	return minDist<=propagationRadius;
}

DefaultProperties
{
	propagationRadius=10000.f

	mMutatorComponentClass=class'WizardGoatComponent'
}