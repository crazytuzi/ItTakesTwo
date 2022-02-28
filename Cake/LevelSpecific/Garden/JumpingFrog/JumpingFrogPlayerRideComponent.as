import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;


void AddJumpingFrog(AJumpingFrog Animal, AHazePlayerCharacter Player)
{
	UJumpingFrogPlayerRideComponent::Get(Player).Frog = Animal;
}

AJumpingFrog GetJumpingFrog(AHazePlayerCharacter Player)
{
	auto Comp = UJumpingFrogPlayerRideComponent::Get(Player);
	if(Comp == nullptr)
		return nullptr;

	return Comp.Frog;
}

UCLASS(Abstract)
class UJumpingFrogPlayerRideComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureGardenFrog MovementFeature;

	UPROPERTY(NotEditable)
	AJumpingFrog Frog;
}