UCLASS(Abstract)
class AQueenFallingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	float TimeShaking;

	UPROPERTY()
	float Offset;

	FVector StartPosition;
	float FallVelocity;

	bool ShouldShake = false;
	bool ShouldFall = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPosition = ActorLocation;
	}

	UFUNCTION()
	void StartShaking()
	{
		System::SetTimer(this, n"StartFalling", TimeShaking, bLooping=false);
		ShouldShake = true;
	}

	UFUNCTION()
	void StartFalling()
	{
		StopShaking();
		ShouldFall = true;
	}

	void StopShaking()
	{
		ShouldShake = false;
		SetActorLocation(StartPosition);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		if (ShouldShake)
		{
			ShakeUpdate(Deltatime);
		}

		else if (ShouldFall)
		{
			FallUpdate(Deltatime);
		}
	}

	void FallUpdate(float Deltatime)
	{
		FallVelocity += 98.2f * Deltatime;

		FVector Location = (FVector::UpVector * - FallVelocity) + ActorLocation;
		SetActorLocation(Location);
	}

	void ShakeUpdate(float DeltaTime)
	{
		FVector Location = Math::RandomPointOnSphere * Offset;
		Location += StartPosition;

		SetActorLocation(Location);
	}
}