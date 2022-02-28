import Peanuts.Network.RelativeCrumbLocationCalculator;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseElectricity;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;
import Vino.Movement.Grinding.UserGrindComponent;

class UMicrophoneChaseRelativeLocationCapability : UHazeCapability
{
	UHazeCrumbComponent CrumbComp;
	UMicrophoneChaseElectricityContainerComponent ElectricityContainer;
	UCharacterMicrophoneChaseComponent MicrophoneChaseComp;
	UUserGrindComponent GrindComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		ElectricityContainer = UMicrophoneChaseElectricityContainerComponent::GetOrCreate(Owner);
		MicrophoneChaseComp = UCharacterMicrophoneChaseComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(ElectricityContainer.Electricity == nullptr)
			return EHazeNetworkActivation::DontActivate;

		/*if(MicrophoneChaseComp.bQuicktimeEvent)
			return EHazeNetworkActivation::DontActivate;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;*/

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(ElectricityContainer.Electricity == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		/*if(MicrophoneChaseComp.bQuicktimeEvent)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(GrindComp.HasActiveGrindSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;*/

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(UMicrophoneChaseRelativeCrumbLocationCalculator::StaticClass(), this, ElectricityContainer.Electricity.RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		CrumbComp.RemoveCustomWorldCalculator(this);
	}
}

class UMicrophoneChaseRelativeCrumbLocationCalculator : UHazeReplicationLocationCalculator
{
	FHazeAcceleratedVector FinalLocation;

	AHazeActor Owner = nullptr;
	USceneComponent RelativeComponent = nullptr;
	UUserGrindComponent GrindComp;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor InOwner, USceneComponent InRelativeComponent)
	{
		Owner = InOwner;
		RelativeComponent = InRelativeComponent;
		GrindComp = UUserGrindComponent::Get(InOwner);
		FinalLocation.Value = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.Location = Owner.GetActorLocation();
		OutTargetParams.CustomLocation = OutTargetParams.Location - RelativeComponent.GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		//const FVector RelativeLocation = RelativeComponent.GetWorldLocation();
		//if(!GrindComp.HasActiveGrindSpline())
		{
			//TargetLocation = RelativeLocation + TargetParams.CustomLocation;
		}
		//else
		{
			//TargetLocation = FromParams.Location;
		}
	}



	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		const FVector RelativeLocation = RelativeComponent.GetWorldLocation();
		//TargetLocation = RelativeLocation + TargetParams.CustomLocation;
		//TargetParams.Location = TargetLocation;
		//const FVector RelativeLocation = RelativeComponent.GetWorldLocation();
		if(!GrindComp.HasActiveGrindSpline())
		{
			TargetParams.Location = RelativeLocation + TargetParams.CustomLocation;
		}
		else
		{
			TargetParams.Location = TargetParams.Location;
		}
		
		//TargetParams.
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
		//FinalLocation.AccelerateTo(TargetLocation, 0.1f, DeltaTime);
		//System::DrawDebugSphere(TargetLocation, 300.0f, 12, FLinearColor::Green);
	}
}

