
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFight180Turn;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightTaunt;

class UFlyingMachineMeleeSquirrelIdleSwapFacingDirectionCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeIdle);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 190;

	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;
	bool bPendingFaceLeft = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		if(!IsStateActive(EHazeMeleeStateType::None) && !IsStateActive(EHazeMeleeStateType::Idle))
			return EHazeNetworkActivation::DontActivate;

		FHazeMeleeTarget PlayerTarget;
		if(!MeleeComponent.GetCurrentTarget(PlayerTarget))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerTarget.bIsToTheRightOfMe)
		{
			if(IsFacingRight())
				return EHazeNetworkActivation::DontActivate;
		}		
		else
		{
			if(!IsFacingRight())
				return EHazeNetworkActivation::DontActivate;
		}
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(IsStateActive(EHazeMeleeStateType::Idle))
			return EHazeNetworkDeactivation::DontDeactivate;

 		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		auto Feature = MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFight180Turn::StaticClass());
		ActivationParams.AddObject(n"Feature", Feature);
		if(IsFacingRight())
			ActivationParams.AddActionState(n"FaceLeft");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto Feature = Cast<ULocomotionFeaturePlaneFight180Turn>(ActivationParams.GetObject(n"Feature"));
		ActivateState(EHazeMeleeStateType::Idle, Feature);
		bPendingFaceLeft = ActivationParams.GetActionState(n"FaceLeft");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		// Swapping face direction is already crumbified
		if(bPendingFaceLeft)
			FaceLeftLocal();
		else
			FaceRightLocal();
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;
	}
}
