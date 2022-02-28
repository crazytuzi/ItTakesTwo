import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomActivationPoints;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomLightStripComponent;
class ALightRoomRotatingBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	ULightRoomLightStripComponent LightStripComponent;

	UPROPERTY()
	ALightRoomActivationPoints ActivationPoint;

	float StartupTimer = 0.f;
	float StartupTimerDuration = 2.f;
	bool bShouldTickStartupTimer = false;
	bool bShouldTickUp = false;

	bool bShouldRotateActor = false;

	float RotationSpeed = 40.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationPoint.ActivationPointActivated.AddUFunction(this, n"ActivationPointActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldRotateActor)
			return;

		if (bShouldTickStartupTimer)
		{
			if (bShouldTickUp)
			{
				StartupTimer += DeltaTime;
				if (StartupTimer >= StartupTimerDuration)
				{
					bShouldTickStartupTimer = false;
					StartupTimer = StartupTimerDuration;
				}
			} else
			{
				StartupTimer -= DeltaTime;
				if (StartupTimer <= 0.f)
				{
					bShouldTickStartupTimer = false;
					StartupTimer = 0.f;
					bShouldRotateActor = false;
				}
			}
		}

		MeshRoot.AddLocalRotation(FRotator(0.f, RotationSpeed * (StartupTimer / StartupTimerDuration) * DeltaTime, 0.f));
	}

	UFUNCTION()
	void ActivationPointActivated(bool bActivated)
	{
		if (bActivated)
		{
			bShouldRotateActor = true;
			bShouldTickUp = true;
			bShouldTickStartupTimer = true;
		} else 
		{
			bShouldTickUp = false;
			bShouldTickStartupTimer = true;
		}
	}
}