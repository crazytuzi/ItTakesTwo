import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrained;

UCLASS(Abstract)
class ATimedPlatformActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformBase;

	UPROPERTY(DefaultComponent, Attach = PlatformBase)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	TArray<AMagneticMoveableObjectConstrained> Levers;

	TArray<bool> LeversReachedEnd;

	float StartPitch = -90.0f;
	float EndPitch = 0.0f;

	float AddedPitch = 0.0f;

	bool bActivated = false;
	bool bAtStartRotation = false;

	float ActivatedTimer = 0.0f;
	float ActivatedDuration = 30.0f;

	float RotationSpeed = 50.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Levers.Num() > 0)
		{
			for(AMagneticMoveableObjectConstrained Lever : Levers)
			{
				LeversReachedEnd.Add(Lever.bReachedEnd);
				Lever.OnMoveableObjectReachedEnd.AddUFunction(this, n"LeverMoved");
			}
		}

		FRotator OriginalRotation = PlatformBase.RelativeRotation;
		PlatformBase.SetRelativeRotation(FRotator(StartPitch, OriginalRotation.Yaw, OriginalRotation.Roll));
		bAtStartRotation = true;
		AddedPitch = StartPitch;
	}

	UFUNCTION()
	void LeverMoved(bool ReachedEnd, AMagneticMoveableObjectConstrained Object)
	{
		int Index = Levers.FindIndex(Object);
		LeversReachedEnd[Index] = ReachedEnd;

		for(bool LeverReachedEnd : LeversReachedEnd)
		{
			if(!LeverReachedEnd)
				return;
		}

		bActivated = true;

		FHazePointOfInterest PoISettings;
		PoISettings.Blend.BlendTime = 2.0f;
		PoISettings.FocusTarget.Component = PlatformBase;
		PoISettings.Duration = 1.0f;
		Game::GetCody().ApplyPointOfInterest(PoISettings, this);
		Game::GetMay().ApplyPointOfInterest(PoISettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bActivated)
		{
			if(bAtStartRotation)
			{
				float Speed = RotationSpeed;

				if(EndPitch < StartPitch)
					Speed = -Speed;

				float DeltaPitch = Speed * DeltaTime;

				if((EndPitch < StartPitch && AddedPitch + DeltaPitch < EndPitch) ||
				(EndPitch > StartPitch && AddedPitch + DeltaPitch > EndPitch))
				{
					DeltaPitch = EndPitch - AddedPitch;
					bAtStartRotation = false;
				}

				PlatformBase.AddLocalRotation(FRotator(DeltaPitch, 0, 0));
				AddedPitch += DeltaPitch;
			}
			if(!bAtStartRotation)
			{
				ActivatedTimer += DeltaTime;
				if(ActivatedTimer > ActivatedDuration)
				{
					ActivatedTimer = 0.0f;
					bActivated = false;
				}
			}

		}
		else
		{
			if(!bAtStartRotation)
			{
				float Speed = RotationSpeed;

				if(StartPitch < EndPitch)
					Speed = -Speed;

				float DeltaPitch = Speed * DeltaTime;

				if((StartPitch < EndPitch && AddedPitch + DeltaPitch < StartPitch) ||
				(StartPitch > EndPitch && AddedPitch + DeltaPitch > StartPitch))
				{
					DeltaPitch = StartPitch - AddedPitch;
					bAtStartRotation = true;
				}

				PlatformBase.AddLocalRotation(FRotator(DeltaPitch, 0, 0));
				AddedPitch += DeltaPitch;
			}
		}
	}

}