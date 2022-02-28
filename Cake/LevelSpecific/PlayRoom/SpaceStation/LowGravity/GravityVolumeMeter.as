import Cake.LevelSpecific.PlayRoom.SpaceStation.LowGravity.LowGravityValve;
import Cake.LevelSpecific.PlayRoom.SpaceStation.LowGravity.LowGravityVolume;
import Vino.Movement.MovementSettings;

UCLASS(Abstract)
class AGravityVolumeMeter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	ALowGravityValve Valve;

	UPROPERTY()
	ALowGravityVolume Volume;

	UPROPERTY(NotEditable)
	int CurrentStep = 2;
}