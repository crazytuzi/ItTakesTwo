

/* 	
	Why? Because sequencer only takes actors as replaceables. 

	The quiver is currently automatically hidden when the 
	player steps into a cutscene by the MatchWielderComponent

	Ask Sydney before you use this! 
*/ 

class AMatchWeaponQuiver : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
}
