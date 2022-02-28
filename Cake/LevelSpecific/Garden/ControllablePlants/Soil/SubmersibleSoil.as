import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

event void FOnCodyBecamePlant();
event void FOnCodyExitSoil();
event void FOnSoilFullyWatered();

class ASubmersibleSoil : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SoilMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ActiveSoilProp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ActiveSoilEffect;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USubmersibleSoilComponent SoilComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GroundPoundWidgetLocation;
	default GroundPoundWidgetLocation.RelativeLocation = FVector(0.f, 0.f, 200.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent Sphere;
	default Sphere.SphereRadius = 1750.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnSoilWateredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnSoilExitedAudioEvent;

	// If true, may first need to water before cody can enter
	UPROPERTY(Category = "Activation")
	bool bRequiresFullyWatered = true;

	UPROPERTY(Category = "Activation")
    bool bStartDisabled = false;

	UPROPERTY(Category = "Activation")
	bool bValidateActivationLevelWhenGroundPound = true;
	
	UPROPERTY(Category = "Soil")
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;

	UPROPERTY(Category = "Soil")
	UNiagaraSystem OnFullyWaterActivateEffect;

	// UPROPERTY(Category = "Soil")
	// UNiagaraSystem ActiveSoilEffectOneOffEffect;

	// Use -1 to skip
	UPROPERTY(Category = "Soil")
	int DynamicMaterialIndex = 0;

	UPROPERTY(Category = "Soil")
	FName WaterAmoungVariableName = n"Tiler_B_Mask_VertexColor";

	// The speed the water increases with when close to 0
	UPROPERTY(Category = "Soil")
	float WaterIncreaseSpeed = 1.5f;

	UPROPERTY()
	FOnCodyBecamePlant OnCodyBecamePlant;

	UPROPERTY()
	FOnCodyExitSoil OnCodyExitSoil;

	UPROPERTY()
	FOnSoilFullyWatered OnFullyWatered;

	UPROPERTY(Transient)
	UHazeUserWidget GPWidget;

	private float CurrentActiveAlpha = 0;
	private bool bIsWaitingForEnable = false;
	private bool bHasBeenWatered = false;
	private UMaterialInstanceDynamic MeshMaterialInstanceDynamic;
	protected bool bWidgetIsVisible = false;
	private bool bWantsToShowWidget = true;
	protected bool bIsInsideWidgetArea = false;

	// Add a water impact component to use the fillspeed of that to fill the soil
	UWaterHoseImpactComponent OptionalWaterImpactComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SoilComp.SoilMesh = SoilMesh;

		bIsWaitingForEnable = bStartDisabled;
		bHasBeenWatered = !bRequiresFullyWatered;
		if(!bHasBeenWatered)
			OptionalWaterImpactComponent = UWaterHoseImpactComponent::Get(this);
		
		if(OptionalWaterImpactComponent != nullptr)
		{
			OptionalWaterImpactComponent.OnFullyWatered.AddUFunction(this, n"OnWaterImpactComponentFullyWatered");
		}

		if(DynamicMaterialIndex >= 0)
			MeshMaterialInstanceDynamic = SoilMesh.CreateDynamicMaterialInstance(DynamicMaterialIndex);

		const float WantedActiveAmount = GetActiveAmount();
		ActiveSoilProp.SetRelativeScale3D(FVector(1.f, 1.f, WantedActiveAmount));
		if(WantedActiveAmount >= 1.f)
		{
			CurrentActiveAlpha = 1.f;
			SetCanBeActivated(true);	
		}
		else
		{
			CurrentActiveAlpha = 0.f;
			SetCanBeActivated(false);
		}
		
		Sphere.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        Sphere.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
		SoilComp.OnPlayerEntered.BindUFunction(this, n"OnEntered");
		SoilComp.OnPlayerExited.BindUFunction(this, n"OnExited");

		UGroundPoundedCallbackComponent GroundPoundComp = UGroundPoundedCallbackComponent::GetOrCreate(this);
		GroundPoundComp.Evaluate.BindUFunction(this, n"EvalOnGroundPounded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const float TargetAlpha = GetActiveAmount();

		if(TargetAlpha != CurrentActiveAlpha)
			SetActiveAmount(FMath::FInterpConstantTo(CurrentActiveAlpha, TargetAlpha, DeltaTime, WaterIncreaseSpeed));

		if(SoilIsActive())
		{
			const float NewSize = FMath::FInterpConstantTo(ActiveSoilProp.GetRelativeScale3D().Z, 1.f, DeltaTime, 2.f);
			ActiveSoilProp.SetRelativeScale3D(FVector(NewSize));
		}
		else
		{
			ActiveSoilProp.SetRelativeScale3D(FVector(0));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected bool EvalOnGroundPounded(AHazePlayerCharacter EnteringPlayer, UPrimitiveComponent Floor)const
	{
		if(EnteringPlayer.IsMay())
		 	return false;
		
		if(!SoilComp.PlantClass.IsValid())
			return false;

		// If specified, this is do make sure that the ground pound hit the soil mesh and not other meshes such as signposts.
		if(SoilComp.SoilMesh != nullptr && Floor != SoilMesh)
			return false;

		if(!bValidateActivationLevelWhenGroundPound)
			return true;

		if(!SoilIsActive())
			return false;

		return true;
	}

	UFUNCTION()
	void SetSoilEnabled(bool Enabled)
	{
		bIsWaitingForEnable = !Enabled;
	}

	UFUNCTION()
	void SetSoilFullyWaterd()
	{
		ApplyWaterImpact();

		if(OptionalWaterImpactComponent != nullptr)
		{
			OptionalWaterImpactComponent.OnFullyWatered.Clear();
			OptionalWaterImpactComponent.bShowWaterWidget = false;
			OptionalWaterImpactComponent.DestroyComponent(this);
			OptionalWaterImpactComponent = nullptr;
		}
		SetActiveAmount(1.f);
	}

	bool IsWaterable()const
	{
		return !bIsWaitingForEnable;
	}

	void SetWidgetCanBeShown(bool bStatus)
	{
		if(bWantsToShowWidget == bStatus)
			return;

		bWantsToShowWidget = bStatus;
		if(!bWantsToShowWidget)
			HideWidget();
		else
			ShowWidget();
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if(OtherActor == Game::GetCody())
		{
			bIsInsideWidgetArea = true;
			ShowWidget();
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if(OtherActor == Game::GetCody())
		{
			bIsInsideWidgetArea = false;
			HideWidget();
		}
    }

	
	UFUNCTION(NetFunction)
	void NetApplyWaterImpact()
	{
		ApplyWaterImpact();
	}
	
	UFUNCTION(NotBlueprintCallable)
	void OnWaterImpactComponentFullyWatered()
	{
		bHasBeenWatered = true;
		OptionalWaterImpactComponent.OnFullyWatered.Clear();
		OptionalWaterImpactComponent.bShowWaterWidget = false;
		OptionalWaterImpactComponent.DestroyComponent(this);
		OptionalWaterImpactComponent = nullptr;

		if(OnFullyWaterActivateEffect != nullptr)
		{
			Niagara::SpawnSystemAtLocation(OnFullyWaterActivateEffect, GetActorLocation(), GetActorRotation());
		}
	}

	void ApplyWaterImpact()
	{
		bHasBeenWatered = true;
	}

	bool ShouldApplyWaterImpact()const
	{
		if(OptionalWaterImpactComponent != nullptr)
			return false;
		return !bHasBeenWatered;
	}

	private float GetActiveAmount()const
	{
		if(bIsWaitingForEnable)
			return 0;
		
		if(bHasBeenWatered)
			return 1.f;

		return CurrentActiveAlpha;
	}

	UFUNCTION(NetFunction)
	void NetSetActiveAmount(float Alpha)
	{
		SetActiveAmount(Alpha);
	}

	void SetActiveAmount(float Alpha)
	{
		const float OldAlphaAmount = CurrentActiveAlpha;
		CurrentActiveAlpha = Alpha;
		if(MeshMaterialInstanceDynamic != nullptr)
			MeshMaterialInstanceDynamic.SetVectorParameterValue(WaterAmoungVariableName, FLinearColor(FMath::Pow(CurrentActiveAlpha, 1.25f), 0.f, 0.f, 0.f));
		
		if(CurrentActiveAlpha > 1.f - KINDA_SMALL_NUMBER && OldAlphaAmount < 1.f)
		{	
			SetCanBeActivated(true);
		}
		else if(CurrentActiveAlpha < 1.f && OldAlphaAmount >= 1.f - KINDA_SMALL_NUMBER)
		{
			SetCanBeActivated(false);
			ActiveSoilProp.SetRelativeScale3D(FVector(1.f, 1.f, 0.f));
		}
	}

	private void SetCanBeActivated(bool bStatus)
	{
		if(bStatus)
		{
			CurrentActiveAlpha = 1.f;
			bIsWaitingForEnable = false;
			bHasBeenWatered = true;
			ActiveSoilEffect.SetHiddenInGame(false);
			Sphere.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			// if(ActiveSoilEffectOneOffEffect != nullptr)
			// 	Niagara::SpawnSystemAtLocation(ActiveSoilEffectOneOffEffect, GetActorLocation() + FVector(0.f, 0.f, 100.f), GetActorRotation());

			OnFullyWatered.Broadcast();

			if(OnSoilWateredEvent != nullptr)
			{
				UHazeAkComponent::HazePostEventFireForget(OnSoilWateredEvent, GetActorTransform());
			}				
		}
		else
		{
			CurrentActiveAlpha = 0.f;
			bHasBeenWatered = false;
			ActiveSoilEffect.SetHiddenInGame(true);
			Sphere.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	bool SoilIsActive()const
	{
		return CurrentActiveAlpha > 1.f - KINDA_SMALL_NUMBER;
	}

	void ShowWidget()
	{
		if(!GroundPoundWidget.IsValid())
			return;
		
		if(bWidgetIsVisible)
			return;
		
		if(!bWantsToShowWidget)
			return;

		if(!bIsInsideWidgetArea)
			return;

		if(GPWidget == nullptr)
			GPWidget = Game::GetCody().AddWidget(GroundPoundWidget);
		else
			Game::GetCody().AddExistingWidget(GPWidget);	

		GPWidget.AttachWidgetToComponent(GroundPoundWidgetLocation);
		bWidgetIsVisible = true;
	}

	void HideWidget()
	{
		if(GPWidget == nullptr)
			return;

		bWidgetIsVisible = false;
		Game::GetCody().RemoveWidget(GPWidget);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnEntered(const FPlayerSubmergedInSoilInfo& PlayerSubmergedInSoilInfo)
	{
		ActiveSoilEffect.SetHiddenInGame(true);
		OnCodyBecamePlant.Broadcast();
		HideWidget();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnExited(const FPlayerSubmergedInSoilInfo& PlayerSubmergedInSoilInfo)
	{
		ActiveSoilEffect.SetHiddenInGame(false);
		Game::GetCody().PlayerHazeAkComp.HazePostEvent(OnSoilExitedAudioEvent);
		ShowWidget();
		OnCodyExitSoil.Broadcast();
	}

	UFUNCTION()
	void DisableSubmersibleSoil()
	{
		SoilComp.bCanEnterSoil = false;
		HideWidget();
		ActiveSoilEffect.SetHiddenInGame(true);
	}
}
