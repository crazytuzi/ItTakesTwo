
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFight180Turn;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightTaunt;

class UFlyingMachineMeleeSquirrelIdleTauntCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeIdle);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	/*  EDITABLE VARIABLES */
	const float TauntMinDistance = 500.f;
	const FHazeMinMax TauntDelay = FHazeMinMax(3.f, 5.f);
	/* */

	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;
	float TimeToTaunt = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
		TimeToTaunt = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			if(SquirrelMeleeComponent.IdleTime >= KINDA_SMALL_NUMBER)
			{
				FHazeMeleeTarget PlayerTarget;
				if(MeleeComponent.GetCurrentTarget(PlayerTarget))
				{
					if(IsStateActive(EHazeMeleeStateType::None)
					 	&& PlayerTarget.Distance.X > TauntMinDistance 
					 	&& GetStateMovementType() == EHazeMeleeMovementType::Idling)
					{
						const float TimeAlpha = FMath::Min((PlayerTarget.Distance.X - TauntMinDistance) / 3000.f, 1.f);
						TimeToTaunt -= DeltaTime + (DeltaTime * TimeAlpha);
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TimeToTaunt > 0)
			return EHazeNetworkActivation::DontActivate;

		if(SquirrelMeleeComponent.IdleTime < 0)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
 		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeToTaunt = FMath::RandRange(TauntDelay.Min, TauntDelay.Max);

		auto Feature = MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightTaunt::StaticClass());
		ActivateState(EHazeMeleeStateType::Idle, Feature);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;
	}
}
