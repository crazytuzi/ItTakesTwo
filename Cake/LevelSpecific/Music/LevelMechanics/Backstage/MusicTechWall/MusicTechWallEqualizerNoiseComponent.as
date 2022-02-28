import Vino.PlayerHealth.PlayerHealthStatics;
class UMusicTechWallEqualizerNoiseComponent : UStaticMeshComponent
{
	default RelativeScale3D = FVector(1.28f, 10.f, 1.28f);
	default RemoveTag(ComponentTags::LedgeGrabbable);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default bGenerateOverlapEvents = true;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UMusicTechWallEqualizerNoiseComponent Neighbour;

	float BarEQPlacement = 0.f;
	float CurrentNoisePlacement = 0.5f;
	float CurrentRightEQPlacement = 0.5f;
	int CurrentNumberOfBars;

	bool bControlledWithLeftStick = false;

	float StartScaleZ = 0.f;
	float TargetScaleZ = 15.f;
	float ScaleZ;
	bool IsTop = false;
	float InterpSpeed = 0.f;

	TSubclassOf<UPlayerDeathEffect> NoiseDeathFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterpSpeed = FMath::RandRange(1.f, 2.f);
		OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}
	
	UFUNCTION()
	void UpdateNoiseComp(float DeltaTime)
	{				
		if (CurrentNoisePlacement <= 0.f)
			ScaleZ = FMath::FInterpTo(RelativeScale3D.Z, 0.f, DeltaTime, InterpSpeed); 
		else
		{
			ScaleZ = FMath::FInterpTo(RelativeScale3D.Z, FMath::Lerp(StartScaleZ, TargetScaleZ, 
			GetLerpValue(CurrentNoisePlacement - BarEQPlacement)), 
			DeltaTime, InterpSpeed); 
		}
		
		SetRelativeScale3D(FVector(RelativeScale3D.X, RelativeScale3D.Y, ScaleZ));

		if(Neighbour != nullptr)
		{
			//																					   v Size of mesh.
			this.SetScalarParameterValueOnMaterials(n"HeightDelta", (ScaleZ - Neighbour.ScaleZ) * 100);
			this.SetScalarParameterValueOnMaterials(n"IsTop", IsTop ? 1 : -1);
		}
	} 

	UFUNCTION()
	void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
			
		if (Player.HasControl())
		{
			KillPlayer(Player, NoiseDeathFX);
		}

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.SetCapabilityActionState(n"AudioOnKilledByNoise", EHazeActionState::ActiveForOneFrame);
	}

	float GetLerpValue(float EQPlacementDifference)
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.f, .1f), FVector2D(1.f, 0.f), FMath::Abs(EQPlacementDifference));
	}
}