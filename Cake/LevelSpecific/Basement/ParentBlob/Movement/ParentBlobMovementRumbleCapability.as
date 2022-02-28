import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobMovementRumbleCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"ParentBlob");

	default TickGroup = ECapabilityTickGroups::GamePlay;

	default CapabilityDebugCategory = n"ParentBlob";

	AParentBlob ParentBlob;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
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
		float OpposeAmount = ParentBlob.PlayerMovementDirection[0].DotProduct(ParentBlob.PlayerMovementDirection[1]);
		float RumbleAmount = 0.f;

		if (OpposeAmount < 0.f)
			RumbleAmount = -OpposeAmount;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (ParentBlob.bBrothersMovementActive && Player.IsCody())
				continue;

			Player.SetFrameForceFeedback(RumbleAmount, RumbleAmount);
		}
	}
};