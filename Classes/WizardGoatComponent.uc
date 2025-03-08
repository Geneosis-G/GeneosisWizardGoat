class WizardGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var WizardGoat myMut;
var float MBDistance;
var float MBSpeed;
var bool moveMB;
var bool moveMBClose;
var bool mIsRightClicking;

var StaticMeshComponent hatMesh;
var MagicBallActor magicBall;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=WizardGoat(owningMutator);

		hatMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( hatMesh, 'hairSocket' );
		magicBall=myMut.Spawn(class'MagicBallActor', gMe);
		//myMut.WorldInfo.Game.Broadcast(myMut, "magicBall=" $ magicBall);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			mIsRightClicking=true;
		}

		if( newKey == 'LEFTCONTROL' || newKey == 'XboxTypeS_DPad_Down')
		{
			magicBall.SetMagicType(magicBall.currentMType+1);
		}

		if(localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ))
		{
			magicBall.ActivateMagic();
		}

		if(localInput.IsKeyIsPressed( "GBA_AbilityAuto", string( newKey ) ))
		{
			magicBall.SwitchMagicEffect();
		}

		if(localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ))
		{
			if(mIsRightClicking)
			{
				moveMB=true;
				moveMBClose=!moveMBClose;
			}
		}

		/*
		if(newKey == 'ONE' || newKey == 'XboxTypeS_Y')
		{
			magicBall.ActivateMagic();
		}

		if(newKey == 'TWO' || newKey == 'XboxTypeS_LeftShoulder')
		{
			magicBall.SwitchMagicEffect();
		}

		if(newKey == 'THREE' || newKey == 'XboxTypeS_RightShoulder')
		{
			if(mIsRightClicking)
			{
				moveMB=true;
				moveMBClose=!moveMBClose;
			}
		}
		*/
	}
	else if( keyState == KS_Up )
	{
		//WorldInfo.Game.Broadcast(self, "KeyUp: "$newKey);
		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			mIsRightClicking=false;
		}

		if(localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ))
		{
			moveMB=false;
		}

		/*
		if(newKey == 'THREE' || newKey == 'XboxTypeS_RightShoulder')
		{
			moveMB=false;
		}
		*/
	}
}

function TickMutatorComponent(float DeltaTime)
{
	super.TickMutatorComponent(deltaTime);

	//Move the magic ball if needed
	if(moveMB)
	{
		if(moveMBClose)
		{
			MBDistance-=MBSpeed;
			MBDistance=MBDistance<0.f?0.f:MBDistance;
		}
		else
		{
			MBDistance+=MBSpeed;
			MBDistance=MBDistance>100000.f?100000.f:MBDistance;
		}
	}

	SetMagicBallLocation();
}

function SetMagicBallLocation()
{
	local vector desiredLocation, closestLocation, camLocation;
	local rotator closestRotation, camRotation;
	local float radius, height;

	gMe.GetBoundingCylinder( radius, height );
	if(gMe.Controller != none && gMe.DrivenVehicle == none)
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	}
	else
	{
		camLocation=gMe.Location;
		camRotation=gMe.Rotation;
	}
	closestRotation.Yaw=camRotation.Yaw;
	closestLocation=gMe.Location;
	closestLocation.Z+=height*2;
	closestLocation+= (vect(1, 0, 0)*radius*4) >> closestRotation;

	desiredLocation=closestLocation;
	desiredLocation+=(vect(1, 0, 0)*MBDistance) >> (camRotation + (rot(1, 0, 0)*10*DegToUnrRot));

	//myMut.WorldInfo.Game.Broadcast(myMut, "goat Location=" $ gMe.Location);
	//myMut.WorldInfo.Game.Broadcast(myMut, "magicBall(" $ magicBall $ ") Location=" $ desiredLocation);

	magicBall.SetLocation(desiredLocation);
}

defaultproperties
{
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Hats.Mesh.WizrdHat'
	End Object
	hatMesh=StaticMeshComp1

	MBDistance=600
	MBSpeed=10
}