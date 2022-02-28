import Vino.Audio.AudioActors.HazeAmbientSound;



struct FCogData
{
	UPROPERTY()
	UStaticMesh MeshToUse;

	UPROPERTY()
	FTransform WorldTransform;

	UPROPERTY()
	FName NameToUse;

	UPROPERTY()
	float TimeForFullCircle = 60;

	UPROPERTY()
	int Steps = 18;

	UPROPERTY()
	bool Reverse = false;

	UPROPERTY()
	UCurveFloat Timeline;

	UPROPERTY(EditConst)
	float RotationPerSteps;

	UPROPERTY(EditConst)
	float TimeBetweenSteps;
	
	UPROPERTY(EditConst)
	float Counter;

	UPROPERTY(EditConst)
	int AudioArrayIndex = -1;
}

enum ECogAudioDataType
{
	UnUsed,
	BeginPlay,
	Tick,
	Ambient
}

struct FCogAudioData
{
	UPROPERTY()
	ECogAudioDataType Type = ECogAudioDataType::UnUsed;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	AHazeAmbientSound AmbientSoundActor;

	UPROPERTY()
	float InitalDelay = 0;

	UPROPERTY()
	UAkAudioEvent Event = nullptr;

	UPROPERTY(EditInstanceOnly)
	int MeshArrayIndex = -1;

	float NextAudioUpdateTime = 0;
}

class UBackgroundCogWheelMesh : UStaticMeshComponent
{
	default SetCollisionProfileName(n"NoCollision");
	default bGenerateOverlapEvents = false;
	default SetCastShadow(false);

	float LastUpdatedGameTime = 0;

	FQuat StartRot;
	FQuat TargetRot;

#if EDITOR
	bool bDebugHasEverBeenUpdated = false;
#endif
	
	void UpdateCog(FCogData& CogData, float GameTime)
	{
		// Get the fraction of how far the wheel ought to have turned 0.0f .. 1.0f
		float StepTime = 1.0 - CogData.Counter / (CogData.TimeBetweenSteps); 

		// Offset 0.0 .. 1.0 => -1.0 .. 1.0 so that we later can clamp 
		// this value to sample 0 from the curve to imitate a delay.
		float OffsetStepTime = StepTime * 2.0 - 1.0; 

		// Print(""+ (1.0 - Counter / (TimeBetweenSteps)));
		float Alpha = CogData.Timeline.GetFloatValue(Math::Saturate(OffsetStepTime));

		const float TickDirection = CogData.Reverse ? -1.0f : 1.0f;

		// Remove deltatime from the time a step is given.
		float TimeLeftToRemove = GameTime - LastUpdatedGameTime;
		const bool bTeleportMesh = TimeLeftToRemove > CogData.TimeBetweenSteps;
		while(TimeLeftToRemove > CogData.TimeBetweenSteps)
		{
			TimeLeftToRemove -= CogData.TimeBetweenSteps;
			TargetRot *= FRotator(0.f, 0.f, CogData.RotationPerSteps * TickDirection).Quaternion();
			StartRot = TargetRot;
		}

		if(bTeleportMesh)
			SetRelativeRotation(TargetRot);
		else
			SetRelativeRotation(FQuat::FastLerp(StartRot, TargetRot, Alpha));

		CogData.Counter -= TimeLeftToRemove;
		if (CogData.Counter < 0.0f)
		{
			StartRot = TargetRot;
			TargetRot *= FRotator(0.f, 0.f, CogData.RotationPerSteps * TickDirection).Quaternion();
			CogData.Counter += CogData.TimeBetweenSteps;
		}

		LastUpdatedGameTime = GameTime;

	#if EDITOR
		bDebugHasEverBeenUpdated = true;
	#endif
	}

	void InitializeRotators(FCogData CogData)
	{
		float Direction = CogData.Reverse ? -1.0f : 1.0f;
		StartRot = RelativeRotation.Quaternion();
		TargetRot = StartRot;
		TargetRot *= FRotator(0.f, 0.f, CogData.RotationPerSteps * Direction).Quaternion();
	}
}
