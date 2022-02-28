import Cake.LevelSpecific.Music.Cymbal.Cymbal;


class UCymbalRelativeLocationCrumbModifierCalculator : UHazeReplicationLocationCalculator
{
	USceneComponent RelativeComponent = nullptr;
	ACymbal Cymbal;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{
		Cymbal = Cast<ACymbal>(Owner);
		Player = Cast<AHazePlayerCharacter>(Cymbal.Owner);
		RelativeComponent = InRelativeComponent;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.Location = Cymbal.ActorCenterLocation;
		OutTargetParams.CustomCrumbVector = Player.ActorCenterLocation;
		OutTargetParams.CustomLocation = TargetRelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		if(!Cymbal.bReturnToOwner)
		{
			const FVector DirectionToTargetFromRemotePlayer = (TargetRelativeLocation - Player.ActorCenterLocation).GetSafeNormal();
			const float DistanceToCymbalControl = (TargetParams.Location - TargetParams.CustomCrumbVector).Size();
			const float DistanceToTargetControl = (TargetParams.CustomLocation - TargetParams.CustomCrumbVector).Size();

			TargetParams.Location = Player.ActorCenterLocation + DirectionToTargetFromRemotePlayer * DistanceToTargetControl * (DistanceToCymbalControl / DistanceToTargetControl);
		}
	}

	FVector GetTargetRelativeLocation() const property
	{
		return RelativeComponent.WorldLocation;
	}
}

class UCymbalRelativeLocationCrumbModifierCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default CapabilityTags.Add(n"Cymbal");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	UHazeCrumbComponent CrumbComponent;
	ACymbal CymbalOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalOwner = Cast<ACymbal>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(CymbalOwner.AutoAimTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(CymbalOwner.bReturnToOwner)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CymbalOwner.AutoAimTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(CymbalOwner.bReturnToOwner)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrumbComponent.MakeCrumbsUseCustomWorldCalculator(UCymbalRelativeLocationCrumbModifierCalculator::StaticClass(), this, CymbalOwner.AutoAimTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComponent.RemoveCustomWorldCalculator(this);
	}
}
