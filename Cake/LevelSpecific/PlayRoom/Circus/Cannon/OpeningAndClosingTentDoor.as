class AOpeningAndClosingTentDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike TimeLike;
	
	UPROPERTY()
	float YawEndAngle;

	UPROPERTY()
	float StartDelay;

	default TimeLike.bLoop = true;
	default TimeLike.bSyncOverNetwork = true;
	default TimeLike.Duration = 1;
	default TimeLike.SyncTag = n"OpeningCloseLoop";

	float StartAngle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartAngle = ActorRotation.Yaw;
		
		if (HasControl())
		{
			if (StartDelay > 0)
			{
				System::SetTimer(this, n"NetStartOscillation", StartDelay, false);
			}
			else
			{
				NetStartOscillation();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetStartOscillation()
	{
		TimeLike.BindUpdate(this, n"UpdateTimeLike");
		TimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		float Yaw = FMath::Lerp(StartAngle, YawEndAngle, Duration);
		FRotator Rotation = MeshRoot.WorldRotation;
		Rotation.Pitch = Yaw;

		MeshRoot.SetWorldRotation(Rotation);
	}
}