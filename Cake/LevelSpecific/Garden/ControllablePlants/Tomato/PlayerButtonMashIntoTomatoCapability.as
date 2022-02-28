import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

event void FOnTomatoButtonMashSuccess();

class UPlayerButtonMashIntoTomatoComponent : UActorComponent
{
	private TSubclassOf<ATomato> _TargetTomatoClass;

	float ButtonMashProgressSpeed = 6.5f;
	float ButtonMashDecay = 12.0f;
	float ButtonMashTotal = 100.0f;
	float ButtonMashCurrent = 0.f;

	private int CurrentIndex = 0;

	UPROPERTY()
	FOnTomatoButtonMashSuccess OnTomatoButtonMashSuccess;

	TSubclassOf<ATomato> GetTargetTomatoClass() const property { return _TargetTomatoClass; }

	void SetTargetTomatoClass(TSubclassOf<ATomato> NewTargetTomatoClass) property
	{
		NetSetTargetTomatoClass(NewTargetTomatoClass);
	}

	UFUNCTION(NetFunction)
	private void NetSetTargetTomatoClass(TSubclassOf<ATomato> NewTargetTomatoClass)
	{
		if(!HasControl())
			return;

		_TargetTomatoClass = NewTargetTomatoClass;
	}

	void ClearTomatoClass()
	{
		_TargetTomatoClass = nullptr;
	}
}

class UPlayerButtonMashIntoTomatoCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UButtonMashProgressHandle ButtonMashHandle;
	UControllablePlantsComponent PlantsComp;
	UPlayerButtonMashIntoTomatoComponent TomatoMash;

	UHazeUserWidget ButtonMashWidgetInstance;

	float CurrentButtonMash = 0.0f;
	bool bButtonMashSuccess = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		TomatoMash = UPlayerButtonMashIntoTomatoComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!TomatoMash.TargetTomatoClass.IsValid())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		bButtonMashSuccess = false;
		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, Player.RootComponent, NAME_None, FVector::ZeroVector);
		CurrentButtonMash = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bButtonMashSuccess)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		DeactivationParams.AddObject(n"TomatoClass", TomatoMash.TargetTomatoClass.Get());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		TSubclassOf<AControllablePlant> TomatoClassToSpawn = Cast<UClass>(DeactivationParams.GetObject(n"TomatoClass"));

		if(TomatoClassToSpawn.IsValid())
		{
			PlantsComp.ActivatePlant(TomatoClassToSpawn);
			TomatoMash.OnTomatoButtonMashSuccess.Broadcast();
		}
		
		StopButtonMash(ButtonMashHandle);
		bButtonMashSuccess = false;
		TomatoMash.ClearTomatoClass();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float ButtonMash = ButtonMashHandle.MashRateControlSide * TomatoMash.ButtonMashProgressSpeed * DeltaTime;
		CurrentButtonMash += ButtonMash;
		bButtonMashSuccess = CurrentButtonMash >= TomatoMash.ButtonMashTotal;
		ButtonMashHandle.Progress = FMath::Min(CurrentButtonMash / TomatoMash.ButtonMashTotal, 1.0f);
		CurrentButtonMash = FMath::Max(CurrentButtonMash - TomatoMash.ButtonMashDecay * DeltaTime, 0.0f);
		TomatoMash.ButtonMashCurrent = CurrentButtonMash;
	}
}
