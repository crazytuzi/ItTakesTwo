class UClockworkSkydivingComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence EnterAnim;

	UPROPERTY()
	UBlendSpace BlendSpace;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SlowCamShake;

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSetting;

}