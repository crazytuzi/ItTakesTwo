import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class UClockworkLastBossFreeFallPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UBlendSpace MovementBlendSpace;

    UPROPERTY()
    UAnimSequence FallingAnimation;

	UPROPERTY()
	UAnimSequence LandingAnimation;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;
}
