import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureCannonFly;
import Vino.PlayerHealth.PlayerDeathEffect;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;

struct FFlyOutOFCanonData
{
	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY()
	ULocomotionFeatureCannonFly Feature;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;
}

struct FShootCanonData
{
	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY()
	UAnimSequence EnterAnimation;

	UPROPERTY()
	UAnimSequence CannonEnterAnimation;

	UPROPERTY()
	UAnimSequence IdleAnimation;

	UPROPERTY()
	FText TutorialText;
}

void SetPlayerBeeingShotByCannon(AHazePlayerCharacter Player, ACannonToShootMarbleActor Instigator)
{
	auto Comp = UCannonToShootMarblePlayerComponent::Get(Player);
	Comp.CannonActor = Instigator;
	Comp.bIsBeeingShot = true;
}

void SetPlayerCannonActor(AHazePlayerCharacter Player, ACannonToShootMarbleActor Instigator)
{
	auto Comp = UCannonToShootMarblePlayerComponent::Get(Player);
	Comp.CannonActor = Instigator;
}

UCLASS(Abstract)
class UCannonToShootMarblePlayerComponent : UActorComponent
{
	bool bIsBeeingShot = false;
	bool bHitBaloon = false;
	ACannonToShootMarbleActor CannonActor;

	UPROPERTY(EditDefaultsOnly)
	FFlyOutOFCanonData FlyOutOfCanonData;

	UPROPERTY(EditDefaultsOnly)
	FShootCanonData ShootCanonData;

}