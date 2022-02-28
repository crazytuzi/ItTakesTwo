class UCharacterSkydiveComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeType;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandingCameraShake;

	UPROPERTY()
	UForceFeedbackEffect LandingForceFeedback;
}