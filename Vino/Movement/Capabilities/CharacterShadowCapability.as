
import Vino.Movement.Components.MovementComponent;


UFUNCTION()
void SetGlassShadow(UMaterialParameterCollection ShadowShaderParameters, FVector pos, float opacity, float radius)
{
	Material::SetVectorParameterValue(ShadowShaderParameters, n"CharacterDecalData1", FLinearColor(pos.X, pos.Y, pos.Z, opacity));
	Material::SetVectorParameterValue(ShadowShaderParameters, n"CharacterDecalData2", FLinearColor(radius, 0, 0, 0));
}

class UCharacterShadowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerShadow");
	default CapabilityTags.Add(n"CharacterShadow");

	default TickGroup = ECapabilityTickGroups::GamePlay;

    UPROPERTY()
    TSubclassOf<ADecalActor> Decal;

    AActor DecalActor;
    UHazeMovementComponent Movement;
	AHazeActor CharacterOwner;
	float LastOpacity;
    
	UPROPERTY()
	UMaterialParameterCollection ShadowShaderParameters;
	
    UPROPERTY()
    UCurveFloat ShadowOpacity;

    UPROPERTY()
    UCurveFloat ShadowSize;

    UMaterialInstanceDynamic DecalMaterial;
	
	int TraceLengthIndex = 0;
	int CurrentTraceIndex = 0;
	float LastValidDistance = -1;
	FName GlassDecalParameterName = n"CodyDecal";

	UHazeAsyncTraceComponent TraceComponent;
	float BonusTraceStart = 0;
	float BonusTraceEnd = 0;
	FVector LastImpactPoint;

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CharacterOwner.bHidden)
        	return EHazeNetworkActivation::DontActivate;

		if(Movement.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(Movement.IsDisabled())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(CharacterOwner.bHidden)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if(Movement.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Movement.IsDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeActor>(Owner);
		TraceComponent = UHazeAsyncTraceComponent::GetOrCreate(CharacterOwner);
        ensure(CharacterOwner != nullptr);
		Movement = UHazeMovementComponent::GetOrCreate(Owner);
        DecalActor = SpawnPersistentActor(Decal, CharacterOwner.ActorLocation, CharacterOwner.ActorRotation);
        DecalMaterial = Cast<ADecalActor>(DecalActor).Decal.CreateDynamicMaterialInstance();
		if(CharacterOwner == Game::GetMay())
			GlassDecalParameterName = n"MayDecal";
		SetDecalHidden(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		DecalActor.DestroyActor();
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetDecalHidden(false);
		LastOpacity = 0.f;
		LastValidDistance = -1;
		LastImpactPoint = CharacterOwner.GetActorLocation();
	}
    
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetDecalHidden(true);
	}
	
	void SetDecalHidden(bool bHidden)
	{
        DecalActor.SetActorHiddenInGame(bHidden);
		// For glass
		if(bHidden)
			Material::SetVectorParameterValue(ShadowShaderParameters, GlassDecalParameterName, FLinearColor(0, 0, 0, 0));
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FVector ShadowLocation = CharacterOwner.GetActorLocation();
		GetTraceValues(CurrentTraceIndex, BonusTraceStart, BonusTraceEnd);

		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(Movement);
		TraceParams.SetToLineTrace();
		
		TraceParams.From = ShadowLocation - (Movement.WorldUp * BonusTraceStart);
		TraceParams.MakeFromRelative(CharacterOwner.RootComponent);
		TraceParams.To = ShadowLocation - (Movement.WorldUp * BonusTraceEnd);
		TraceParams.MakeToRelative(CharacterOwner.RootComponent);

		TraceComponent.TraceSingle(TraceParams, this, n"TraceGroundComplete");
    }

	UFUNCTION(NotBlueprintCallable)
	void TraceGroundComplete(UObject TraceInstigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		FVector ShadowLocation = CharacterOwner.GetActorLocation();
		bool bFoundGround = Obstructions.Num() > 0;
		if(bFoundGround)
		{
			FHitResult Hit = Obstructions[0];
			TraceLengthIndex = CurrentTraceIndex;
			LastValidDistance = Hit.Distance + BonusTraceStart;
			ShadowLocation = Hit.ImpactPoint;
		}
		else
		{
			if(CurrentTraceIndex == TraceLengthIndex)
				TraceLengthIndex = FMath::Min(TraceLengthIndex + 1, 3);

			ShadowLocation = CharacterOwner.GetActorLocation().ConstrainToPlane(Movement.WorldUp);
			ShadowLocation += LastImpactPoint.ConstrainToDirection(Movement.WorldUp);
		}

		CurrentTraceIndex++;

		// Restart the trace again
		if(CurrentTraceIndex > TraceLengthIndex)
			CurrentTraceIndex = 0;

		bFoundGround = LastValidDistance >= 0;
        const float Opacity = ShadowOpacity != nullptr ? ShadowOpacity.GetFloatValue(LastValidDistance) : 1.f;
        const float Scale = ShadowSize.GetFloatValue(LastValidDistance) * CharacterOwner.ActorScale3D.Z;
		
		// Stop rendering the decal entirely if it's faded out
		if (!bFoundGround || Opacity <= 0.01f)
		{
			if(!DecalActor.bHidden)
			{
				SetDecalHidden(true);
			}
		}
		else if(DecalActor.bHidden 
			|| LastOpacity != Opacity 
			|| LastImpactPoint.DistSquared(ShadowLocation) > KINDA_SMALL_NUMBER)
		{
			SetDecalHidden(false);
			FLinearColor Color = FLinearColor(0.0, 0.0, 0.0, Opacity);
			DecalMaterial.SetVectorParameterValue(n"BaseColor", Color);

			DecalActor.SetActorLocation(ShadowLocation);
		
			DecalActor.SetActorRotation(FRotator::MakeFromZ(Movement.WorldUp));
			DecalActor.SetActorRotation(FRotator(90,0,0));
			DecalActor.SetActorRelativeScale3D(FVector(Scale, Scale, Scale));
			
			// For glass
			Material::SetVectorParameterValue(ShadowShaderParameters, GlassDecalParameterName, FLinearColor(ShadowLocation.X, ShadowLocation.Y, ShadowLocation.Z, Opacity));
			LastImpactPoint = ShadowLocation;
		}

		LastOpacity = Opacity;
	}

	// we step through the trace amount so we dont trace so long and only 1 trace each frame
	void GetTraceValues(int Index, float& OutStart, float& OutEnd)const
	{
		if(Index == 1)
		{
			OutStart = 500.f;
			OutEnd = 1000.f;
		}
		else if(Index == 2)
		{
			OutStart = 1000.f;
			OutEnd = 2000.f;
		}
		else if(Index == 3)
		{
			OutStart = 2000.f;
			OutEnd = 5000.f;
		}
		else
		{
			OutStart = 0.f;
			OutEnd = 500.f;
		}
	}
}
