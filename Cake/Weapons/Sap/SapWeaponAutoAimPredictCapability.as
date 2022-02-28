import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Peanuts.Aiming.AutoAimStatics;

class USapWeaponAutoAimPredictCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(SapWeaponTags::Weapon);
//	default CapabilityTags.Add(SapWeaponTags::Aim);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 102;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;
	USceneComponent Target;

	FVector LastLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		/*
		if (Target != Wielder.AimTarget.Component)
		{
			Target = Wielder.AimTarget.Component;

			if (Target != nullptr)
				LastLocation = Target.WorldLocation;
		}

		if (Target != nullptr)
		{
			// Predict component velocity
			FVector Location = Target.WorldLocation;
			FVector AimPredictVelocity = (Location - LastLocation) / DeltaTime;

			// Account for distance to the predicted ACymbalSwingPoint
			AimPredictVelocity *= 1.f + Target.Distance(Owner.ActorLocation) / 6000.f;

			//Wielder.AimPredictVelocity = FMath::VInterpTo(Wielder.AimPredictVelocity, AimPredictVelocity, Settings.AimPredictionLerpCoefficient, DeltaTime);

			LastLocation = Target;
		}
		else
		{
			//Wielder.AimPredictVelocity = FVector::ZeroVector;
		}
		*/
	}
}