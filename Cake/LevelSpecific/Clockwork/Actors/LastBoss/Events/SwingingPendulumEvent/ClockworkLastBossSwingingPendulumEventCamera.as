class AClockworkLastBossSwingingPendulumEventCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	FRotator CamStartRot;
	FRotator CamTargetRot;

	FVector CamStartLoc;
	FVector CamTargetLoc;

	float CamStartFOV = 70.f;
	float CamTargetFOV = 60.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CamStartLoc = Camera.RelativeLocation;
		CamTargetLoc = CamStartLoc + FVector(0.f, 0.f, -100.f);

		CamStartRot = Camera.RelativeRotation;
		CamTargetRot = CamStartRot + FRotator(5.f, 0.f, 0.f);

		Camera.Settings.bUseFOV = true;
	}
}