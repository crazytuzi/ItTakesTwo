
UCLASS(Abstract)
class AMagneticSpinningPlatform : AActor
{
	float StartRotion;
	float CurrentRotation;

	UPROPERTY()
	float RotationSpeedMultiplier = 2;

	
	UPROPERTY()
	TArray<FVector> StopVector;

	int CurrentStopRotationIndex;

	float StoppedTimer = 0;
	float StartPitch = 0;

	FVector StartRightVector;
	FVector StarUpVector;
	FQuat StartRotation;

	UPROPERTY()
	bool RotateForward = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = ActorQuat;
		StartRightVector = ActorRightVector;
		StartPitch = ActorRotation.Pitch;
		StarUpVector = ActorUpVector;
		DetermineRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SpinUpdate(DeltaTime);
	}

	void SpinUpdate(float DeltaTime)
	{
		if (RotateForward)
		{
			if (ActorUpVector.DotProduct(StopVector[CurrentStopRotationIndex]) > 0.999f)
			{
				StoppedTimer += DeltaTime;
				if (StoppedTimer > 2)
				{
					IterateToNextRotation();
				}
			}

			else
			{
				CurrentRotation += DeltaTime * RotationSpeedMultiplier;
			}
		}

		else
		{
			if (ActorUpVector.DotProduct(StarUpVector) > 0.96f ||
				ActorUpVector.DotProduct(StarUpVector * -1) > 0.98f)
			{
				//Do nothing!
			}

			else
			{
				CurrentRotation += DeltaTime * RotationSpeedMultiplier;
				
			}
		}

		FQuat RotationAroundRightVector =  FQuat(StartRightVector, FMath::DegreesToRadians(CurrentRotation));

		SetActorRotation(RotationAroundRightVector * StartRotation);
	}

	void DetermineRotation()
	{
		if (ActorUpVector.DotProduct(StarUpVector) > 0.5f)
		{
			CurrentStopRotationIndex = 1;
		}

		else
		{
			CurrentStopRotationIndex = 0;
		}
	}

	void IterateToNextRotation()
	{
		// Modulus, what is that?
		CurrentStopRotationIndex++;

		if (CurrentStopRotationIndex > StopVector.Num() - 1)
		{
			CurrentStopRotationIndex = 0;
		}

		StoppedTimer = 0;
	}

	UFUNCTION()
	void StopUpdate()
	{
		RotateForward = false;
		CurrentStopRotationIndex = 0;
	}

	UFUNCTION()
	void StartUpdate()
	{
		RotateForward = true;
		DetermineRotation();
	}
}