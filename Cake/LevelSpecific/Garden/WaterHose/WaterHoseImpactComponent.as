import Vino.ActivationPoint.ActivationPointStatics;

event void FOnHitWithWater();
event void FOnFullyWatered();
event void FOnFullyWithered();
event void FOnWateringBegin();
event void FOnWateringEnd();
event void FOnWaterProjectileImpact(FHitResult Hit);

enum EWaterImpactType
{
	// Valid if the actor is hit
	EntireActor,

	// Valid only of the parent component is hit
	ParentComponent
};

/* The component that stores all the current impact componets
 * Needs to be its own component since the waterhose component might not have been created yet.
*/
class UWaterHoseImpactContainerComponent : UActorComponent
{
    TArray<UWaterHoseImpactComponent> CollectedImpactComponents;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CollectedImpactComponents.Reserve(30);
    }
}

UCLASS(HideCategories = "ComponentReplication Activation Tags AssetUserData Collision Cooking")
class UWaterHoseImpactComponent : UHazeActivationPoint
{
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryOtherFrame;
	default ValidationType = EHazeActivationPointActivatorType::May;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 12000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 8000.f);
	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/Garden/WaterHose/WBP_WaterHoseImpactIcon.WBP_WaterHoseImpactIcon_C");

	UPROPERTY()
	FOnHitWithWater OnHitWithWater;

	UPROPERTY()
	FOnWaterProjectileImpact OnWaterProjectileImpact;

	UPROPERTY()
	FOnFullyWatered OnFullyWatered;

	UPROPERTY()
	FOnFullyWithered OnFullyWithered;

	UPROPERTY()
	FOnWateringBegin OnWateringBegin;

	UPROPERTY()
	FOnWateringEnd OnWateringEnd;

	// How the water impact is looking for the impact component
	UPROPERTY(Category = "WaterLevel")
	EWaterImpactType ImpactValidation = EWaterImpactType::EntireActor;

	// How fast the water level rises
	UPROPERTY(Category = "WaterLevel")
	float FillSpeed = 1.f;

	// How fast the fill speed accelerates when watering
	UPROPERTY(Category = "WaterLevel")
	float FillAccelerationSpeed = 1.25f;

	// How fast the fill speed decelerates when you stop watering (it will basically keep growing for a short while after you stop watering)
	UPROPERTY(Category = "WaterLevel")
	float FillDecelerationSpeed = 1.5f;

	// How long it takes for the plant to start decaying after you stop watering
	UPROPERTY(Category = "WaterLevel")
	float TimeUntilDecay = 4.f;

	// How fast the water level decays once TimeUntilDecay has been reached
	UPROPERTY(Category = "WaterLevel")
	float DecaySpeed = 1.f;

	// How fast the decay speed accelerates
	UPROPERTY(Category = "WaterLevel")
	float DecayAccelerationSpeed = 0.5f;

	UPROPERTY(Category = "WaterLevel")
	float OverrideTimeToDisable = -1.f;

	float CurrentAcceleration = 0.f;
	float CurrentDecaySpeed = 0.f;

	UPROPERTY(Category = "Color")
	TArray<FWaterLevelColor> PlantColors;

	UPROPERTY(Category = "Attribute|Widget")
	bool bShowWaterWidget = true;

	bool bBeeingHitByWater = false;
	bool bFullyWatered = false;
	bool bFullyWithered = false;

	float TimeSinceHitWithWater = 0.f;
	bool bWantedStatusIsHitByWater = false;
	float TimeUntilNotHitByWater = 0;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnWaterStartImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnWaterStopImpactEvent;

	UHazeSmoothSyncFloatComponent SyncComponent;
	AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto ContainerComponent = UWaterHoseImpactContainerComponent::GetOrCreate(Game::GetMay());
	 	ContainerComponent.CollectedImpactComponents.Add(this);
		HazeOwner = Cast<AHazeActor>(Owner);

		// Only may can fill the component so make it snappy for her
		HazeOwner.SetControlSide(Game::GetMay());

		SyncComponent = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"WaterSyncComponent");
		// Tick last so we get the updates from the player
		SyncComponent.SetTickGroup(ETickingGroup::TG_PostPhysics);
		SyncComponent.MakeNetworked(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		auto ContainerComponent = UWaterHoseImpactContainerComponent::GetOrCreate(Game::GetMay());
	 	ContainerComponent.CollectedImpactComponents.Remove(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto ContainerComponent = UWaterHoseImpactContainerComponent::GetOrCreate(Game::GetMay());
	 	ContainerComponent.CollectedImpactComponents.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Don't disable until we are finished
		if(CurrentWaterLevel > 0)
			return true;

		auto ContainerComponent = UWaterHoseImpactContainerComponent::GetOrCreate(Game::GetMay());
	 	ContainerComponent.CollectedImpactComponents.Remove(this);
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bBeeingHitByWater)
			OnHitWithWater.Broadcast();

		if(HasControl())
		{
			if (bBeeingHitByWater)
			{
				TimeSinceHitWithWater = 0.f;
				CurrentDecaySpeed = 0.f;
				CurrentAcceleration += FillAccelerationSpeed * DeltaTime;	
				TimeUntilNotHitByWater -= DeltaTime;	
			}
			else
			{
				TimeSinceHitWithWater += DeltaTime;
				CurrentAcceleration -= FillDecelerationSpeed * DeltaTime;
			}

			CurrentAcceleration = FMath::Clamp(CurrentAcceleration, 0.f, 1.f);

			// Update the water level
			float NewWaterLevel = -1;
			if (TimeSinceHitWithWater >= TimeUntilDecay && TimeUntilDecay > 0)
			{
				CurrentDecaySpeed += DecayAccelerationSpeed * DeltaTime;
				NewWaterLevel = SyncComponent.Value - DecaySpeed * CurrentDecaySpeed * DeltaTime;
			}
			else
			{
				NewWaterLevel = SyncComponent.Value + FillSpeed * CurrentAcceleration * DeltaTime;
			}

			SyncComponent.Value = FMath::Clamp(NewWaterLevel, 0.f, 1.f);

			// Conditionally broadcast the water level
			SetFullyWatered(SyncComponent.Value >= 1.f);		
			SetFullyWithered(SyncComponent.Value <= 0.f);	

			if(TimeUntilNotHitByWater <= 0 || !PlayerCanValidate(Game::GetMay()))
				EndHitByWater();
		}
		
		// We can now stop the ticking
		if(HazeOwner.IsActorDisabled() && SyncComponent.Value <= 0.f)
		{
			SetComponentTickEnabled(false);
		}

		bWantedStatusIsHitByWater = false;
	}

	
	bool ValidateImpact(USceneComponent ImpactComponent) const
	{
		if(!PlayerCanValidate(Game::GetMay()))
			return false;

		if(ImpactComponent == nullptr)
			return false;

		if(ImpactValidation == EWaterImpactType::EntireActor)
			return true;

		TArray<USceneComponent> Parents;
		GetParentComponents(Parents);
		if(Parents.Num() == 0)
			return true;

		return Parents[0] == ImpactComponent;
	}

	UFUNCTION()
	void UpdateColorBasedOnWaterLevel(UStaticMeshComponent MeshComp, TArray<FWaterLevelColor> ColorInfo)
	{
		const float WaterValue = GetCurrentWaterLevel();
		for (int Index = 0, Count = ColorInfo.Num(); Index < Count; ++Index)
		{
			FLinearColor CurColor = FLinearColor(FMath::Lerp(ColorInfo[Index].StartColor.R, ColorInfo[Index].EndColor.R, WaterValue), 
												FMath::Lerp(ColorInfo[Index].StartColor.G, ColorInfo[Index].EndColor.G, WaterValue), 
												FMath::Lerp(ColorInfo[Index].StartColor.B, ColorInfo[Index].EndColor.B, WaterValue), 
												FMath::Lerp(ColorInfo[Index].StartColor.A, ColorInfo[Index].EndColor.A, WaterValue));
			MeshComp.SetColorParameterValueOnMaterialIndex(ColorInfo[Index].MaterialIndex, n"AlbedoColor", CurColor);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentWaterLevel() const property
	{
		return SyncComponent.Value;
	}

	void BeginHitByWater(float TimeToDisable)
	{
		if(!HasControl())
			return;

		// Only controlside counts down
		TimeUntilNotHitByWater = OverrideTimeToDisable > 0.f ? OverrideTimeToDisable : TimeToDisable;
		//Print("TimeUntilNotHitByWater: " + TimeUntilNotHitByWater);

		if(!bBeeingHitByWater)
		{
			NetBeginHitByWater();
		}	
	}

	UFUNCTION(NetFunction)
	void NetBeginHitByWater()
	{
		bBeeingHitByWater = true;
		OnWateringBegin.Broadcast();
	}

	void EndHitByWater()
	{
		if(!HasControl())
			return;

		if(!bBeeingHitByWater)
			return;	

		TimeUntilNotHitByWater = 0;
		NetEndHitByWater();
	}

	UFUNCTION(NetFunction)
	void NetEndHitByWater()
	{
		bBeeingHitByWater = false;
		OnWateringEnd.Broadcast();
	}

	private void SetFullyWatered(bool bStatus)
	{
		if(bStatus == bFullyWatered)
			return;

		if(!HasControl())
			return;

		NetSetFullyWatered(bStatus);
	}

	UFUNCTION(NetFunction)
	void NetSetFullyWatered(bool bStatus)
	{
		bFullyWatered = bStatus;
		if(bFullyWatered)
		{
			if(HasControl())
				ApplyFullyWatered();
			else // We give remote some time so sync up
				System::SetTimer(this, n"ApplyFullyWatered", Network::GetPingRoundtripSeconds() * 1.5f, false);	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ApplyFullyWatered()
	{
		OnFullyWatered.Broadcast();
	}

	private void SetFullyWithered(bool bStatus)
	{
		if(bStatus == bFullyWithered)
			return;

		if(!HasControl())
			return;

		NetSetFullyWithered(bStatus);
	}

	UFUNCTION(NetFunction)
	void NetSetFullyWithered(bool bStatus)
	{
		bFullyWithered = bStatus;
		if(bFullyWithered)
		{
			if(HasControl())
				ApplyFullyWithered();
			else // We give remote some time so sync up
				System::SetTimer(this, n"ApplyFullyWithered", Network::GetPingRoundtripSeconds() * 1.5f, false);
		}	
	}

	UFUNCTION(NotBlueprintCallable)
	protected void ApplyFullyWithered()
	{
		OnFullyWithered.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{	
		if(!bShowWaterWidget)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(GetCurrentWaterLevel() >= 0)
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::Invalid;
	}
	
	UFUNCTION()
	void ResetWaterLevel()
	{
		SetFullyWatered(false);
		SyncComponent.Value = 0.f;
	}
}

UCLASS(abstract)
class UWaterHoseImpactActivationPointWidget : UHazeActivationPointWidget
{
	UPROPERTY(BlueprintReadOnly)
	UWaterHoseImpactComponent OwningWaterPoint;

	UPROPERTY(BlueprintReadOnly)
	float CurrentWidgetRadialProgress = 0;

	UPROPERTY(BlueprintReadOnly)
	bool bBeeingHitByWater = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OwningWaterPoint = Cast<UWaterHoseImpactComponent>(GetOwningPoint());
		CurrentWidgetRadialProgress = OwningWaterPoint.GetCurrentWaterLevel();	
		bBeeingHitByWater = OwningWaterPoint.bBeeingHitByWater;
	}

	UFUNCTION(BlueprintOverride)
	void InitializeForQuery(FHazeQueriedActivationPoint Query, EHazeActivationPointWidgetStatusType InVisibility)
	{
		CurrentWidgetRadialProgress = OwningWaterPoint.GetCurrentWaterLevel();	
		bBeeingHitByWater = OwningWaterPoint.bBeeingHitByWater;
	}
}

struct FWaterLevelColor
{
	UPROPERTY()
	int MaterialIndex;

	UPROPERTY()
	FLinearColor StartColor;

	UPROPERTY()
	FLinearColor EndColor;
}