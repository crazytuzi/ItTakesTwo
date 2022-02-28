

enum ETrapStage
{
	None,
	Electify,
	AcornCrusher,
}

UCLASS(Abstract)
class ATrapCage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bDisabledAtStart = true;
	default Disable.bRenderWhileDisabled = true;
	default Disable.bCollideWhileDisabled = true;

	UPROPERTY()
	UCurveFloat AcornCrusherMovement;

	UPROPERTY()
	UCurveFloat AcornCrusherSize;

	UPROPERTY()
	float AcornCrushTimeMultiplier = 0.5f;

	UPROPERTY()
	float AcornCrushTime = 2.5f;

	UPROPERTY()
	float BeginAcornCrushRotation = 0.5f;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UNiagaraComponent ElectricEffectTop;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UNiagaraComponent ElectricEffectBottom;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent AcornCrucherStart;

	UPROPERTY(DefaultComponent, Attach = AcornCrucherStart)
	USceneComponent AcornCrucherEnd;

	UPROPERTY(DefaultComponent, Attach = AcornCrucherStart)
	USceneComponent AcornCrucherRoot;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent AcornRespawn;

	UPROPERTY(DefaultComponent, Attach = AcornCrucherRoot)
	UStaticMeshComponent AcornCrucherMesh;
	default AcornCrucherMesh.SetCollisionProfileName(n"NoCollision");

	ETrapStage CurrentState = ETrapStage::None;
	float CurrentStateTime = 0;

	// Acorn
	float ActornDelay = 0;
	bool bActornCrusherHasCrushed = false;
	float EndCrusherTime = 0;
	float CurrentRotationSpeed = 0;
	const float MinScale = KINDA_SMALL_NUMBER;
	FVector OriginalScale;

	// Electric
	int ElectrifyCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float Min;
		AcornCrusherMovement.GetTimeRange(Min, EndCrusherTime);
		OriginalScale = AcornCrucherRoot.GetRelativeScale3D();
		AcornCrucherMesh.SetHiddenInGame(true);
	}

	// BP expose
	UFUNCTION(BlueprintEvent)
	void OnStateEnd(ETrapStage State){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentState == ETrapStage::AcornCrusher)
		{			
			ActornDelay += DeltaSeconds;
			if(ActornDelay > 2.f)
			{
				CurrentStateTime = FMath::Min(CurrentStateTime + (DeltaSeconds * AcornCrushTimeMultiplier), EndCrusherTime);

				// We need to scale up the actor so it stays inside the cage
				const float SizeAlpha = AcornCrusherSize.GetFloatValue(CurrentStateTime);
				AcornCrucherRoot.SetRelativeScale3D(FVector(
					FMath::Lerp(MinScale, OriginalScale.X, SizeAlpha), 
					OriginalScale.Y, 
					FMath::Lerp(MinScale, OriginalScale.Z, SizeAlpha)));
			
				// Update the up and down movement
				const float CurrentOffsetAlpha = AcornCrusherMovement.GetFloatValue(CurrentStateTime);
				FVector WantedLocation = AcornCrucherStart.GetWorldLocation();
				WantedLocation.Z = FMath::Lerp(AcornCrucherStart.GetWorldLocation().Z, AcornCrucherEnd.GetWorldLocation().Z, CurrentOffsetAlpha);
				AcornCrucherRoot.SetWorldLocation(WantedLocation);

				// Update the rotation movement
				if(CurrentStateTime >= BeginAcornCrushRotation)
					CurrentRotationSpeed = FMath::Min(CurrentRotationSpeed + (DeltaSeconds * 300), 500.f);
				AcornCrucherMesh.AddLocalRotation(FRotator(CurrentRotationSpeed * DeltaSeconds, 0.f, 0.f));
					
				if(!bActornCrusherHasCrushed && CurrentStateTime >= FMath::Min(AcornCrushTime, EndCrusherTime))
				{
					bActornCrusherHasCrushed = true;
					AcornCrusherCrush();
				}

				// Reset and end
				if(CurrentStateTime >= EndCrusherTime)
				{
					StopActornCrusher();
				}
			}	
		}
	}

	// From bp
	UFUNCTION()
	void TriggerElectrify()
	{
		CurrentState = ETrapStage::Electify;
		ElectrifyCount++;
	}

	UFUNCTION(BlueprintEvent)
	void ElectrifyEnd(bool bKillPlayer){}

	// From player comp
	void StopElectrify(bool bKillPlayer)
	{
		CurrentStateTime = 0;
		ElectricEffectTop.Deactivate();
		ElectricEffectBottom.Deactivate();
		CurrentState = ETrapStage::None;
		ElectrifyEnd(bKillPlayer);
		OnStateEnd(ETrapStage::Electify);
	}

	UFUNCTION()
	void StartActornCrusher()
	{
		CurrentState = ETrapStage::AcornCrusher;
		AcornCrucherRoot.SetRelativeScale3D(FVector(MinScale, OriginalScale.Y, MinScale));
		AcornCrucherMesh.SetHiddenInGame(false);
	}

	void StopActornCrusher()
	{
		ActornDelay = 0;
		CurrentRotationSpeed = 0;
		CurrentStateTime = 0;
		bActornCrusherHasCrushed = false;
		CurrentState = ETrapStage::None;
		AcornCrucherMesh.SetHiddenInGame(true);
		OnStateEnd(ETrapStage::AcornCrusher);
	}

	// BP expose
	UFUNCTION(BlueprintEvent)
	void AcornCrusherCrush(){}

	// BP expose
	UFUNCTION(BlueprintEvent)
	void AcornCrusherEnd(){}
}