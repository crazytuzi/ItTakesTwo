
/*
	We use this to store information on the player
	When being attacked by the waternado
*/

class UWaternadoPlayerResponseComponent : UActorComponent
{
	/* whether the player has been impulsed and is currently flying.
	 this will reset as soon as the player land */
	bool bNadoSkydiving = false;
}