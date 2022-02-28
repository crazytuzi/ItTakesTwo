struct FBeetleShockwave
{
	UNiagaraComponent Effect = nullptr;
	UStaticMeshComponent MeshComp = nullptr;
	float Speed = 0.f;
	FVector Origin;
	float MajorRadius = 0.f;
	float MinorRadius = 0.f;
	float ExpirationTime = 0.f;
	TArray<AHazePlayerCharacter> ValidTargets;
}

class UBeetleShockwaveComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem ShockwaveEffect = nullptr;

	UPROPERTY()
	UStaticMesh ShockwaveMesh = nullptr;

	UPROPERTY()
	UForceFeedbackEffect ShockwaveForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ShockwaveCameraShake;

	int NumPendingShockwaves = 0;
	TArray<FBeetleShockwave> Shockwaves;
	TArray<UStaticMeshComponent> AvailableMeshes;
	
	// Set by entrance behaviour
	float ShockWaveHeight = BIG_NUMBER;

	void TriggerShockwave()
	{
		if (ShockWaveHeight == BIG_NUMBER)
			ShockWaveHeight = Owner.ActorLocation.Z;
		
		// We should only keep track of shockwaves on control side, e.g. so we won't have any 
		// loitering pending shockwaves if we switch control side
		if (HasControl())	
			NumPendingShockwaves++; 
	}

	FVector GetShockwaveMeshScale(float MajorRadius, float MinorRadius)
	{
		return FVector(MajorRadius * 0.0095f, MajorRadius * 0.0095f, MajorRadius * 0.005f);	
	}

	default PrimaryComponentTick.bStartWithTickEnabled = false;
}