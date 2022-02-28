
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Peanuts.Triggers.BoxShapeActor;

event void FOnSubmersibleSoilPlantSprayerFullyPlantedEvent(ASubmersibleSoilPlantSprayer Area);
event void FOnSubmersibleSoilPlantSprayerPercentagePlantedEvent(ASubmersibleSoilPlantSprayer Area);
event void FOnSubmersibleSoilPlantSprayerPercentageChangedEvent(ASubmersibleSoilPlantSprayer Area, float NewPercentage);
delegate void FOnSubmersibleSoilPlantSprayerPercentagePlantedSignature(ASubmersibleSoilPlantSprayer Area);

/******************************************************************************/
struct FSubmersibleSoilPercentageEvent
{
	bool bHasTriggered = false;
	float Percentage = 0;
	FOnSubmersibleSoilPlantSprayerPercentagePlantedEvent Event;
}

/******************************************************************************/
class USeedSprayerWitherSimulationContainerComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	ASeedSprayerWitherSimulation ColorSystem = nullptr;

	ASubmersibleSoilPlantSprayer ActiveSoil = nullptr;
}

struct GoopStartSquare
{
	UPROPERTY(Meta = (MakeEditWidget))
	FVector Location;

	UPROPERTY()
	float Radius = 250;
}

/******************************************************************************/
UCLASS()
class ASeedSprayerWitherSimulation : APaintablePlane
{
	UPROPERTY(Category = "Water")
	float WaterStrength = 0.25f;

	default bInvertDebugAlpha = false;
	default bDebugAlphaIsWhite = true;

	UPROPERTY(Category = "Water")
	bool GoopStartPreview = false;

	UPROPERTY(Category = "Water")
	TArray<GoopStartSquare> GoopStartLocations;

	UPROPERTY(Category = "Water")
	UTexture2D GoopStartTexture;

	UPROPERTY(Category = "Water")
	float GoopStartLocationsCPUSideScale = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Clear(FLinearColor(0.f, 0.f, 0.f, 0.f));

		SetActorTickEnabled(false);
		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
            auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::GetOrCreate(Player);
			Reset::RegisterPersistentComponent(ColorContainerComponent);
            ColorContainerComponent.ColorSystem = this;
		}

		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors);
		for(AActor OverlappingActor : OverlappingActors)
		{
			ActorBeginOverlap(OverlappingActor);
		}

		// Set the texture to have goop on it when we start
		StartGoop();
	}

	void StartGoop()
	{
		LerpAndDrawTexture(GetActorLocation(), 1000000.0f, FLinearColor(0, 0, 0, 0), FLinearColor(1, 1, 1, 1), false, nullptr, true, FLinearColor(1,1,1,1), false);
		for (int i = 0; i < GoopStartLocations.Num(); i++)
		{
			LerpAndDrawTexture(GetActorLocation() + GoopStartLocations[i].Location * GetActorScale3D(), GoopStartLocations[i].Radius, FLinearColor(0, 0, 1, 0), FLinearColor(1, 1, 1, 1), false, GoopStartTexture, true, FLinearColor(1,1,1,1), false, GoopStartLocationsCPUSideScale);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Super::EndPlay(Reason);

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Player);
			if(ColorContainerComponent  != nullptr)
			{
				ColorContainerComponent.ColorSystem = nullptr;
				Reset::UnregisterPersistentComponent(ColorContainerComponent);
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);
		if(GoopStartPreview)
		{
			StartGoop();
		}
	}

	bool AreaHasBeenWatered(FVector WorldLocation, float Radius, float RequiredPercentage = 1.f)
	{
		TArray<int> Box;
		GetIndicesInCircle(WorldLocation, Radius, Box);
		if(Box.Num() <= 0)
			return false;

		int PaintedIndex = 0;
		for(int i = 0; i < Box.Num(); i++)
		{
			FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
			if(Index.Color.B > 0.f && RequiredPercentage >= 1.f) // If it has goop, it has not been watered.
				return false;
			else if(Index.Color.B <= 1.f - KINDA_SMALL_NUMBER) // If it does not have goop, count it for the percentage.
				PaintedIndex++;		
		}

		const float PaintedAmount = float(PaintedIndex) / float(Box.Num());
		return PaintedAmount >= RequiredPercentage;
	}

	void GetWateredWorldLocations(FVector CenterLocation, FVector Extends, TArray<FVector>& OutWateredLocations)
	{
		TArray<int> Box;
		GetIndicesInRect(CenterLocation, Extends, Box);
		for(int i = 0; i < Box.Num(); i++)
		{
			FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
			if(Index.Color.B >= 1.f - KINDA_SMALL_NUMBER)
				OutWateredLocations.Add(ArrayLocationToWorldLocation(Box[i]));
		}
	}

	FLinearColor GetFlowerFillColor()const property
	{
		return FLinearColor(1.f, 1.f, 0.f, 1.f);
	}

	bool PaintFlowerTypeOneOnLocation(FVector WorldLocation, float Radius, bool bRequiredWater = false)
	{
		TArray<int> Box;
		GetIndicesInCircle(WorldLocation, Radius, Box);
		FLinearColor FlowerTypeOneColor = FLinearColor(1.f, 0.f, 0.f, 0.f);
		return PaintFlowerTypeOnBox(Box, WorldLocation, Radius, bRequiredWater, FlowerTypeOneColor);
	}

	bool PaintFlowerTypeTwoOnLocation(FVector WorldLocation, float Radius, bool bRequiredWater = false)
	{
		TArray<int> Box;
		GetIndicesInCircle(WorldLocation, Radius, Box);
		FLinearColor FlowerTypeTwoColor = FLinearColor(0.f, 1.f, 0.f, 0.f);
		return PaintFlowerTypeOnBox(Box, WorldLocation, Radius, bRequiredWater, FlowerTypeTwoColor);

	}

	bool PaintFlowerTypeThreeOnLocation(FVector WorldLocation, float Radius, bool bRequiredWater = false)
	{
		TArray<int> Box;
		GetIndicesInCircle(WorldLocation, Radius, Box);
		FLinearColor FlowerTypeThreeColor = FLinearColor(0.f, 0.f, 0.f, 1.f);
		return PaintFlowerTypeOnBox(Box, WorldLocation, Radius, bRequiredWater, FlowerTypeThreeColor);
	}

	bool PaintFlowerTypeOnBox(TArray<int> Box, FVector WorldLocation, float TexturePaintRadius, bool bRequiredWater, FLinearColor FlowerColor)
	{
		if(bRequiredWater && !CanPaintFlowerAt(Box))
			return false;
		
		bool bPainted = true;
		for(int i = 0; i < Box.Num(); i++)
		{
			FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
			Index.Color.R = FlowerColor.R;
			Index.Color.G = FlowerColor.G;
			Index.Color.A = FlowerColor.A;

			// We have water (Goop has been painted away)
			if(Index.Color.B < 1.f)
				Index.bHasBeenPainted = true;
			else
				bPainted = false;
		}

		if(TargetRenderTexture != nullptr)
		{
			LerpAndDrawTexture(WorldLocation, TexturePaintRadius, FlowerColor, FlowerFillColor, bHasBeenPaintedStatus = bPainted, EditCPUSideData = false);
		}
		
		return bPainted;
	}
	
	/* Will fill paint the area with flowers
	 *@bBroadcast; will trigger the 'FullyPlanted' event if true
	*/
	UFUNCTION()
	void ForceComplete(ASubmersibleSoilPlantSprayer Soil, bool bBroadcast = false)
	{
		const TArray<int>& SoilRect = Soil.GetRectArea(this);

		FVector MayLocation = Game::GetMay().GetActorLocation();

		const float ZHeight = Soil.GetActorLocation().Z + 300.f;
		const FLinearColor FlowerColor(0.f, 0.f, 0.f, 1.f);
		
		FVector Origin;
		FVector Extends;
		GetActorBounds(false, Origin, Extends);
		const float TexturePaintRadius = (Extends.Size() / CPUSideResolution) * FMath::Sqrt(3.f);
		for(int i = 0; i < SoilRect.Num(); i++)
		{
			FWitherSimulationArrayData& Index = CPUSideData[SoilRect[i]];
			Index.Color = FlowerColor;
			Index.bHasBeenPainted = true;

			FVector WorldPosition = ArrayLocationToWorldLocation(SoilRect[i]);
			WorldPosition.Z = ZHeight;
			LerpAndDrawTexture(WorldPosition, TexturePaintRadius, FlowerColor, FLinearColor(1.f, 1.f, 1.f, 1.f), EditCPUSideData = false);
		}

		Soil.TriggerFullyPlantedInternal(this, bBroadcast);
	}

	FLinearColor GetWaterColor() const property
	{
		return FLinearColor(0.0f, 0.0f, 0.0f, 0.0f);
	}

	FLinearColor GetGoopColor() const property
	{
		return FLinearColor(0.0f, 0.0f, 1.0f, 0.0f);
	}

	FLinearColor GetWaterFillStrength() const property
	{
		return FLinearColor(0.0f, 0.0f, 0.25f, 0.0f);
	}

	void PaintWaterOnLocation(FVector WorldLocation, float Radius)
	{
		bool bPainted = true;
		TArray<int> Box;
		GetIndicesInCircle(WorldLocation, Radius, Box);
		for(int i = 0; i < Box.Num(); i++)
		{
			FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
			Index.Color.B = 0.f;

			if(Index.Color.A > 0 && (Index.Color.R > 0 || Index.Color.G > 0))
				Index.bHasBeenPainted = true;
			else	
				bPainted = false;
		}

		if(TargetRenderTexture != nullptr)
		{	
			LerpAndDrawTexture(WorldLocation, Radius, WaterColor, WaterFillStrength, bHasBeenPaintedStatus = bPainted, EditCPUSideData = false);
		}
	}

	bool CanPaintFlowerAt(const TArray<int>& Box)
	{
		if(Box.Num() <= 0)
			return false;

		int ValidNumbers = 0;

		float WaterMedian = 0;
		for(int i = 0; i < Box.Num(); i++)
		{
			if(!ArrayLocationIsValid(Box[i]))
				continue;

			const FWitherSimulationArrayData& Index = CPUSideData[Box[i]];
			WaterMedian += Index.Color.B;
			ValidNumbers++;
		}

		if(ValidNumbers > 0)
		{
			WaterMedian /= ValidNumbers;
			return WaterMedian >= 0.8f;
		}

		return false;
	}

	float GetWaterAmountFromColor(FLinearColor FromColor) const
	{
		return FromColor.B;
	}
	
	void ApplyWaterAmountToColor(FLinearColor& ToColor, float WaterAmount)
	{
		ToColor.B = WaterAmount;
	}

	void IncreaseWaterToColor(FLinearColor& ToColor, float DeltaTime, float Speed)
	{
		ToColor.B = FMath::FInterpConstantTo(ToColor.B, 1.f, DeltaTime, Speed);
	}

	// Will test if the area has been fully planted and broadcast FullyPlanted if true
	UFUNCTION()
	void UpdateFullyPlanted(ASubmersibleSoilPlantSprayer Soil)
	{
		if(Soil == nullptr)
			return;

		if(!Soil.bCanBeCompleted)
			return;

		if(Soil.bHasBeenFullyPlanted)
			return;

		const float Percentage = GetPaintedPercentage(Soil.GetRectArea(this));
		if(Percentage >= Soil.RequierdPercentageForFullyPlanted)
			Soil.TriggerFullyPlanted(this);	
	}

	void UpdatePercentageEvents(ASubmersibleSoilPlantSprayer Soil)
	{
		if(Soil == nullptr)
			return;

		UpdatePlantedPercentageEvents(Soil);
		UpdateWateredPercentageEvents(Soil);
	}

	private void UpdatePlantedPercentageEvents(ASubmersibleSoilPlantSprayer Soil)
	{
		if(Soil.PercentagePlantedEvents.Num() <= 0 && !Soil.OnPlantedPercentageChange.IsBound())
			return;
			
		// const FVector Origin = Soil.FlowerArea.GetWorldLocation();
		// const FVector Extends = Soil.FlowerArea.GetScaledBoxExtent();
		const float PercentageFilled = GetPaintedPercentage(Soil.GetRectArea(this));
		Soil.UpdatePlantedPercentageEvents(PercentageFilled);
	}

	private void UpdateWateredPercentageEvents(ASubmersibleSoilPlantSprayer Soil)
	{
		if(Soil.PercentageWateredEvents.Num() <= 0)
			return;
			
		const float PercentageFilled = GetSoilWateredPercentage(Soil);
		Soil.UpdateWateredPercentageEvents(PercentageFilled);
	}

	float GetSoilWateredPercentage(ASubmersibleSoilPlantSprayer Soil)
	{
		if(Soil == nullptr)
			return -1;

		const FVector Origin = Soil.FlowerArea.GetWorldLocation();
		const FVector Extends = Soil.FlowerArea.GetScaledBoxExtent();
		FLinearColor WaterFillColor = GoopColor * WaterStrength;
		return GetSoilColorPercentage(Soil.GetRectArea(this), WaterColor, WaterFillColor);
	}

	float GetSoilColorPercentage(TArray<int> Box, FLinearColor TargetColor, FLinearColor Opacity) const
	{
		const int MaxAmount = Box.Num();

		if(MaxAmount <= 0)
			return 0.f;

		int PaintedAmount = 0;
		for(int i = 0; i < MaxAmount; i++)
		{	
			if(Opacity.R > 0 && CPUSideData[Box[i]].Color.R != TargetColor.R)
				continue;

			if(Opacity.G > 0 && CPUSideData[Box[i]].Color.G != TargetColor.G)
				continue;

			if(Opacity.B > 0 && CPUSideData[Box[i]].Color.B != TargetColor.B)
				continue;

			if(Opacity.A > 0 && CPUSideData[Box[i]].Color.A != TargetColor.A)
				continue;

			PaintedAmount++;
		}

		return float(PaintedAmount) / float(MaxAmount);
	}
	
}

struct FSubmersibleSoilPlantSprayerForceSoilData
{
	const float DelayBetween = 0.2f;
	const float PercentageColorChange = 85.f;

	ASeedSprayerWitherSimulation PaintablePlane;
	float DelayBetweenPaints = DelayBetween;
	TArray<FVector> WorldPositions;
	TArray<int> ColorsAtWorldPositions;
	int PaintTimes = 5.f;
	int Index = 0;

	void UpdateForceComplete(ASubmersibleSoilPlantSprayer Soil, float DeltaTime)
	{
		DelayBetweenPaints -= DeltaTime;
		if(DelayBetweenPaints <= 0)
		{
			DelayBetweenPaints = DelayBetween;
			PaintTimes--;
	
			const float Radius = PaintablePlane.GetCpuDataSize().Size() * 20;
			for(int i = 0; i < WorldPositions.Num(); ++i)
			{
				if(ColorsAtWorldPositions[i] == 0)
					PaintablePlane.PaintFlowerTypeOneOnLocation(WorldPositions[i], Radius);
				else if(ColorsAtWorldPositions[i] == 1)
					PaintablePlane.PaintFlowerTypeTwoOnLocation(WorldPositions[i], Radius);
				else
					PaintablePlane.PaintFlowerTypeThreeOnLocation(WorldPositions[i], Radius);

				PaintablePlane.PaintWaterOnLocation(WorldPositions[i], Radius);
			}

		}	
	}
}

/******************************************************************************/
class ASubmersibleSoilPlantSprayer : ASubmersibleSoil
{
	default DynamicMaterialIndex = -1;
	default bIsInsideWidgetArea = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent FlowerArea;
	default FlowerArea.BoxExtent = FVector(400.f, 400.f, 200.f);

	UPROPERTY(Category = "Events")
	APaintablePlane GoopPlane;
	
	// Called then the painted percentage is 100
	UPROPERTY(Category = "Events")
	FOnSubmersibleSoilPlantSprayerFullyPlantedEvent FullyPlanted;

	// Called every time the percentage change
	UPROPERTY(Category = "Events")
	FOnSubmersibleSoilPlantSprayerPercentageChangedEvent OnPlantedPercentageChange;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnSeedsprayerGroundPoundHitAudioEvent;
	
	UPROPERTY(Category = "Activation", EditInstanceOnly, BlueprintReadOnly)
	bool bCanBeWatered = true;

	UPROPERTY(Category = "Activation", EditInstanceOnly, BlueprintReadOnly)
	bool bCanBePlanted = true;

	UPROPERTY(Category = "Activation", EditInstanceOnly, BlueprintReadOnly)
	bool bCanBeCompleted = true;

	UPROPERTY(Category = "Activation", EditInstanceOnly, BlueprintReadOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float RequierdPercentageForFullyPlanted = 0.99f;

	UPROPERTY(Category = "Activation", EditInstanceOnly, BlueprintReadOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float RequierdPercentageForFullyWatered = 0.99f;

	UPROPERTY(EditInstanceOnly, Category = "Soil")
	TArray<ABoxShape> IgnorePercentageShapes;

	/* This is only for helping to debug the current percentage that has been painted
	 * This variable is not included in the final version of the game
	*/
	UPROPERTY(EditConst, Category = "Debug")
	float DebugCurrentPaintedPercentage = 0;
	float LastDebugCurrentPaintedPercentage = 0;

	bool bHasBeenFullyPlanted = false;
	TArray<FSubmersibleSoilPercentageEvent> PercentagePlantedEvents;
	private float LastPlantedPercentage = -1;
	private FVector LastWidgetLocation;

	TArray<FSubmersibleSoilPercentageEvent> PercentageWateredEvents;
	private float LastWateredPercentage = -1;

	TArray<FSubmersibleSoilPlantSprayerForceSoilData> ForcedToCompletion;
	TArray<int> CpuDataIndicies;
	bool bHasAppliedFirstWaterImpact = false;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		// This actor needs to be axis aligned
		SetActorRotation(FRotator(0, 0, 0));
		FlowerArea.SetRelativeRotation(FRotator::ZeroRotator);	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SoilComp.OnPlayerSubmergedInSoil.AddUFunction(this, n"HandlePlayerSubmergedInSoil");
		LastWidgetLocation = GroundPoundWidgetLocation.WorldLocation;

		for(auto BoxShape : IgnorePercentageShapes)
		{
			if(BoxShape == nullptr)
				continue;

			BoxShape.SetActorRotation(FRotator::ZeroRotator);
		}
	}

#if EDITOR
	APaintablePlane DebugPlane;
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);


		// for(int i = ForcedToCompletion.Num() - 1; i >= 0; --i)
		// {
		// 	if(ForcedToCompletion[i].PaintablePlane != nullptr)
		// 		ForcedToCompletion[i].UpdateForceComplete(this, DeltaTime);

		// 	if(ForcedToCompletion[i].PaintTimes <= 0)
		// 		ForcedToCompletion.RemoveAtSwap(i);
		// }

		if(bWidgetIsVisible)
		{	
			auto Cody = Game::GetCody();
			const FVector PlayerLocation = Cody.GetActorLocation();
			auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Cody);
			
			const FVector Origin = FlowerArea.GetWorldLocation();
			const FVector Extends = FlowerArea.GetScaledBoxExtent();

			TArray<FVector> WateredLocations;
			ColorContainerComponent.ColorSystem.GetWateredWorldLocations(Origin, Extends, WateredLocations);
			int ValidLocations = 0;
			if(WateredLocations.Num() > 0)
			{
				FVector MedianLocation;
				for(FVector Loc : WateredLocations)
				{
					float Multiplier = 1;
					const float DistSq = Loc.DistSquared2D(PlayerLocation);
					if(DistSq < FMath::Square(1000.f))
						Multiplier = 50;
					else if(DistSq < FMath::Square(5000.f))
						Multiplier = 2;

					MedianLocation += Loc * Multiplier;
					ValidLocations += Multiplier;
				}

				if(ValidLocations > 0)
				{
					MedianLocation /= ValidLocations;
					if(LastWidgetLocation.DistSquared2D(MedianLocation) > FMath::Square(300.f))
					{
						const FVector NewWorldLocation = FMath::VInterpTo(
						GroundPoundWidgetLocation.WorldLocation, 
						FVector(MedianLocation.X, MedianLocation.Y, GroundPoundWidgetLocation.WorldLocation.Z), 
						DeltaTime, 
						1.25f);

						GroundPoundWidgetLocation.WorldLocation = NewWorldLocation;
						LastWidgetLocation = NewWorldLocation;
					}
					
				}
			}


		}
		
		// Debug
	#if EDITOR
		if(DebugPlane == nullptr)
		{
			TArray<AActor> FoundActors;
			Gameplay::GetAllActorsOfClass(APaintablePlane::StaticClass(), FoundActors);
			for(int i = 0; i < FoundActors.Num(); ++i)
			{
				APaintablePlane FoundPlane = Cast<APaintablePlane>(FoundActors[i]);
				if(FoundPlane.DebugCPUSideData && !FoundPlane.IsActorDisabled())
				{
					DebugPlane = FoundPlane;
					break;
				}
			}
		}

		if(DebugPlane != nullptr)
		{
			auto SeedSprayerWitherSimulation = Cast<ASeedSprayerWitherSimulation>(DebugPlane);

			const FVector Origin = FlowerArea.GetWorldLocation();
			const TArray<int>& SoilRect = GetRectArea(DebugPlane);
			DebugPlane.DebugDrawCpuData(SoilRect, Editor::IsSelected(this), Origin.Z);
			
			DebugCurrentPaintedPercentage = DebugPlane.GetPaintedPercentage(SoilRect);
			if(LastDebugCurrentPaintedPercentage != DebugCurrentPaintedPercentage)
			{
				LastDebugCurrentPaintedPercentage = DebugCurrentPaintedPercentage;
				Print("Flower %: " + DebugCurrentPaintedPercentage);
			}
		}
	
	#endif
	}

	const TArray<int>& GetRectArea(APaintablePlane ForPlane)
	{
		if(CpuDataIndicies.Num() == 0)
		{
			const FVector Origin = FlowerArea.GetWorldLocation();
			const FVector Extends = FlowerArea.GetScaledBoxExtent();
	
			ForPlane.GetIndicesInRect(Origin, Extends, CpuDataIndicies);

			for(auto BoxShape : IgnorePercentageShapes)
			{
				if(BoxShape == nullptr)
					continue;

				const FVector IngoreOrigin = BoxShape.Root.GetWorldLocation();
				const FVector IngoreExtends = BoxShape.Root.GetScaledBoxExtent();

				TArray<int> IgnoreBox;
				ForPlane.GetIndicesInRect(IngoreOrigin, IngoreExtends, IgnoreBox);

				for(int i = 0; i < IgnoreBox.Num(); ++i)
				{
					CpuDataIndicies.RemoveSwap(IgnoreBox[i]);
				}
			}
		}

		return CpuDataIndicies;
	}

	bool ShouldApplyWaterImpact()const override
	{
		return !bHasAppliedFirstWaterImpact;
	}

	void ApplyWaterImpact() override
	{
		bHasAppliedFirstWaterImpact = true;
		SetWidgetCanBeShown(true);
		ShowWidget();
	}

	UFUNCTION()
	void SetPlantable(bool bStatus)
	{
		bCanBePlanted = bStatus;
	}

	UFUNCTION()
	void SetCompleteable(bool bStatus)
	{
		bCanBeCompleted = bStatus;
	}

	UFUNCTION()
	void SetWaterable(bool bStatus)
	{
		bCanBeWatered = true;
	}

	bool IsWaterable()const override
	{
		return bCanBeWatered && Super::IsWaterable();
	}

	UFUNCTION()
	void HandlePlayerSubmergedInSoil(const FPlayerSubmergedInSoilInfo& PlayerSubmergedInSoilInfo)
	{
		auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(PlayerSubmergedInSoilInfo.Player);
		ColorContainerComponent.ActiveSoil = this;
	}

	// Percentage is 0 to 1
	UFUNCTION()
	void AddPaintedEvent(FOnSubmersibleSoilPlantSprayerPercentagePlantedSignature Event, float Percentage)
	{
		FSubmersibleSoilPercentageEvent NewEvent;
		NewEvent.Percentage = FMath::Clamp(Percentage, 0.f, 1.f);
		NewEvent.Event.AddUFunction(Event.GetUObject(), Event.GetFunctionName());
		PercentagePlantedEvents.Add(NewEvent);
	}

	// Percentage is 0 to 1
	UFUNCTION()
	void AddWaterdEvent(FOnSubmersibleSoilPlantSprayerPercentagePlantedSignature Event, float Percentage)
	{
		FSubmersibleSoilPercentageEvent NewEvent;
		NewEvent.Percentage = FMath::Clamp(Percentage, 0.f, 1.f);
		NewEvent.Event.AddUFunction(Event.GetUObject(), Event.GetFunctionName());
		PercentageWateredEvents.Add(NewEvent);
	}

	UFUNCTION(NetFunction)
	void NetTriggerFullyPlanted(ASeedSprayerWitherSimulation Plane)
	{
		TriggerFullyPlantedInternal(Plane, true);
	}

	// We use codys controlside to update the fully planted since he is mostly planting
	void TriggerFullyPlanted(ASeedSprayerWitherSimulation Plane)
	{
		if(bHasBeenFullyPlanted)
			return;

		if(!Game::GetCody().HasControl())
			return;

		NetTriggerFullyPlanted(Plane);
	}

	void TriggerFullyPlantedInternal(ASeedSprayerWitherSimulation Plane, bool bBroadCast)
	{
		ActiveSoilEffect.SetHiddenInGame(true);
		Sphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		bHasBeenFullyPlanted = true;
		FullyPlanted.Broadcast(this);

		FSubmersibleSoilPlantSprayerForceSoilData NewData;
		NewData.PaintablePlane = Plane;
		DisableSubmersibleSoil();
		//const FVector Origin = FlowerArea.GetWorldLocation();
		//const FVector Extends = FlowerArea.GetScaledBoxExtent();

		// int width = 4;
		// int height = 4;
		// for (int x = 0; x < width; x++)
		// {
		// 	for (int y = 0; y < height; y++)
		// 	{
		// 		// loop indexes rescaled to go from -1 and +1
		// 		float fx = ((x / float(width  - 1)) - 0.5f) * 2.0f;
		// 		float fy = ((y / float(height - 1)) - 0.5f) * 2.0f;

		// 		const FVector WorldPosition = Origin + Extends * FVector(fx, fy, 0);
				
		// 		NewData.WorldPositions.Add(WorldPosition);

		// 		const float RandomValue = FMath::RandRange(0.f, 100.f);
		// 		if(RandomValue < NewData.PercentageColorChange * 0.5f)
		// 			NewData.ColorsAtWorldPositions.Add(0);
		// 		else if(RandomValue > 100.f - NewData.PercentageColorChange * 0.5f)
		// 			NewData.ColorsAtWorldPositions.Add(1);
		// 		else
		// 			NewData.ColorsAtWorldPositions.Add(2);
		// 	}
		// }
		//ForcedToCompletion.Add(NewData);
	}

	void UpdatePlantedPercentageEvents(float NewPercentage)
	{
		if(FMath::Abs(LastPlantedPercentage - NewPercentage) < KINDA_SMALL_NUMBER)
			return;

		LastPlantedPercentage = NewPercentage;
		if(OnPlantedPercentageChange.IsBound())
			OnPlantedPercentageChange.Broadcast(this, NewPercentage);

		for(int i = 0; i < PercentagePlantedEvents.Num(); ++i)
		{
			if(NewPercentage >= PercentagePlantedEvents[i].Percentage)
			{
				if(PercentagePlantedEvents[i].Event.IsBound())
					PercentagePlantedEvents[i].Event.Broadcast(this);
			}
		}
	}

	void UpdateWateredPercentageEvents(float NewPercentage)
	{
		if(FMath::Abs(LastWateredPercentage - NewPercentage) < KINDA_SMALL_NUMBER)
			return;

		LastWateredPercentage = NewPercentage;

		for(int i = 0; i < PercentageWateredEvents.Num(); ++i)
		{
			if(PercentageWateredEvents[i].bHasTriggered)
				continue;

			if(NewPercentage < PercentageWateredEvents[i].Percentage)
				continue;

			PercentageWateredEvents[i].bHasTriggered = true;
			if(PercentageWateredEvents[i].Event.IsBound())
				PercentageWateredEvents[i].Event.Broadcast(this);
		}
	}

	protected bool EvalOnGroundPounded(AHazePlayerCharacter EnteringPlayer, UPrimitiveComponent Floor)const
	{
		if(EnteringPlayer.IsMay())
		 	return false;
		
		if(!SoilComp.PlantClass.IsValid())
			return false;

		EnteringPlayer.PlayerHazeAkComp.HazePostEvent(OnSeedsprayerGroundPoundHitAudioEvent);

		// If specified, this is do make sure that the ground pound hit the soil mesh and not other meshes such as signposts.
		if(SoilComp.SoilMesh != nullptr && Floor != SoilMesh)
			return false;

		if(SoilIsActive())
			return true;
		
		const FVector PlayerLocation = EnteringPlayer.GetActorLocation();
		auto ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(EnteringPlayer);

		const float Radius = ColorContainerComponent.ColorSystem.GetCpuDataSize().Size() + 50.f;
		//System::DrawDebugCircle(PlayerLocation, Radius + EnteringPlayer.GetCollisionSize().X, 36, Duration = 3.f, ZAxis = FVector(1.f, 0.f, 0.f));
		if(!ColorContainerComponent.ColorSystem.AreaHasBeenWatered(PlayerLocation, Radius, 0.01f))
			return false;

		return true;
	}
}
