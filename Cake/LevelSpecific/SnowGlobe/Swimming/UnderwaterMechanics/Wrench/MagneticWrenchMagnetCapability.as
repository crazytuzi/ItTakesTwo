import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;

class UMagneticWrenchMagnetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Wrench");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	AMagneticWrenchActor Wrench;
	UHazeMovementComponent MoveComp;
	FMagneticWrenchSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Wrench = Cast<AMagneticWrenchActor>(Owner);
		MoveComp = Wrench.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ApplyForceForMagnet(Wrench.RedMagnet, DeltaTime);
		ApplyForceForMagnet(Wrench.BlueMagnet, DeltaTime);
	}

	void ApplyForceForMagnet(UMagneticWrenchComponent Magnet, float DeltaTime)
	{
		FVector TotalForce;

		TArray<FMagnetInfluencer> Influencers;
		Magnet.GetInfluencers(Influencers);

		for(auto Influencer : Influencers)
		{
			if (!Influencer.IsActive())
				continue;

			auto MagnetComp = UMagneticComponent::Get(Influencer.Influencer);

			FVector Diff = MagnetComp.WorldLocation - Magnet.WorldLocation;
			FVector Dir = Diff.GetSafeNormal();
			float DiffMagnitude = Diff.Size();

			// If we're _too_ close to the magnet we dont want to pull it,
			//	since that will make the magnet go inside the player which is annoying
			if (DiffMagnitude < Settings.MagnetMinRange)
				continue;

			Diff -= Dir * Settings.MagnetMinRange;
			DiffMagnitude -= Settings.MagnetMinRange;

			// Calculate magnitude of force
			// If both players are holding onto the magnet, we want a bit of extra kick
			float ForceMag = Settings.MagnetWrenchForce;
			if (Wrench.AreBothPlayersActive())
				ForceMag += Settings.BothPlayersForceExtra;

			// Cap the force to max range
			FVector Force = Dir * Math::Saturate(DiffMagnitude / Settings.MagnetMaxRange) * ForceMag;

			if (!Magnet.HasOppositePolarity(MagnetComp))
				Force = -Force;

			TotalForce += Force;
		}

		if (TotalForce.IsNearlyZero())
			return;

		Wrench.ApplyForce(Magnet.WorldLocation, TotalForce, DeltaTime);
	}
}
