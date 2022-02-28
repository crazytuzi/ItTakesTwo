import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.PillowFort.SideInteractions.WindUpRadarStationActor;


//Communicate progress to actor.
//Constant decay / Decay only when not interacted with (spinning down)?


class URadarStationMashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Interaction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UButtonMashProgressHandle ButtonMashHandle;
	AWindupRadarStationActor RadarActor;

	float CurrentButtonMash = 0.0f;
	float Progress = 0;
	float ButtonMashProgressSpeed = 8.0f;
	float ButtonMashDecay = 12.0f;
	float ButtonMashTotal = 100.0f;
	bool bButtonMashSuccess = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"ButtonMashing"))
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"ButtonMashing"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	// UFUNCTION(BlueprintOverride)
	// void OnActivated(FCapabilityActivationParams ActivationParams)
	// {
	// 	Player = Cast<AHazePlayerCharacter>(Owner);
	// 	ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, Player.RootComponent, NAME_None, FVector::ZeroVector);
	// 	RadarActor = Cast<AWindupRadarStationActor>(GetAttributeObject(n"RadarActor"));

	// 	Progress = RadarActor.WindUpProgress;
	// 	CurrentButtonMash = Progress * 100;
	// 	ButtonMashHandle.Progress = Progress;

	// 	Player.BlockCapabilities(n"Movement", this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	// {
	// 	StopButtonMash(ButtonMashHandle);
	// 	bButtonMashSuccess = false;
	// 	RadarActor.OnInteractionExit(Player, Progress);
	// 	Player.UnblockCapabilities(n"Movement", this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if(!bButtonMashSuccess)
	// 	{
	// 		const float ButtonMash = ButtonMashHandle.MashRateControlSide * ButtonMashProgressSpeed * DeltaTime;
	// 		CurrentButtonMash += ButtonMash;
	// 		bButtonMashSuccess = CurrentButtonMash >= ButtonMashTotal;

	// 		Progress = FMath::Min(CurrentButtonMash / ButtonMashTotal, 1.0f);

	// 		ButtonMashHandle.Progress = Progress;

	// 		//CurrentButtonMash = FMath::Max(CurrentButtonMash - ButtonMashDecay * DeltaTime, 0.0f);
	// 	}

	// 	if(IsActioning(ActionNames::Cancel))
	// 		Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Inactive);
	// }
}