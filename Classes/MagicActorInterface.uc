interface MagicActorInterface;

static function bool IsValidActor(Actor act);
function Actor GetMagicActor();
function EnableMagic(Actor act, optional bool enableForever);
function DisableMagic(optional bool forceStop);

DefaultProperties
{

}