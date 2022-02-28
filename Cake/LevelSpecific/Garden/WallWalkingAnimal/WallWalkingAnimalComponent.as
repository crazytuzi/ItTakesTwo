import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalLaunchPreviewActor;

void AddWallWalkingAnimal(AWallWalkingAnimal Animal, AHazePlayerCharacter Player)
{
	UWallWalkingAnimalComponent PlayerComp = UWallWalkingAnimalComponent::Get(Player);
	PlayerComp.CurrentAnimal = Animal;	
}

UCLASS(Abstract)
class UWallWalkingAnimalComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureGardenSpider MovementFeature;

	UPROPERTY(NotEditable)
	AWallWalkingAnimal CurrentAnimal;

	UPROPERTY(EditDefaultsOnly)
	UWallWalkingAnimalCameraSettings CamSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset AimCamSettings;

	FName LastAudioSpiderStandState = n"";
}