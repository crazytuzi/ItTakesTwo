import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;

class UParentBlobButtonHoldInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	UParentBlobButtonHoldComponent ButtonHoldComp;

	bool bPlayingBlendSpace = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		ButtonHoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ButtonHoldComp.bButtonHoldActive)
			return EHazeNetworkActivation::DontActivate;

		if (!ButtonHoldComp.bCurrentButtonHoldIsInteraction)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ButtonHoldComp.bButtonHoldActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayingBlendSpace = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bPlayingBlendSpace)
		{
			ParentBlob.StopBlendSpace();
			ParentBlob.UnblockCapabilities(CapabilityTags::Movement, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float HorizontalBlendSpaceValue = 0.f;
		float VerticalBlendSpaceValue = 0.f;

		bool bAtLeastOnePlayerHolding = false;
		bool bMayTryingToMove = false;
		bool bCodyTryingToMove = false;

		if (ButtonHoldComp.bMayHolding)
		{
			bAtLeastOnePlayerHolding = true;
			HorizontalBlendSpaceValue -= 1.f;
			VerticalBlendSpaceValue = 1.f;
		}
		else
		{
			FVector MovementDir = ParentBlob.PlayerMovementDirection[Game::GetMay()];
			float MoveDot = ParentBlob.ActorForwardVector.DotProduct(MovementDir);
			if (MoveDot < 0.f)
				bMayTryingToMove = true;
		}

		if (ButtonHoldComp.bCodyHolding)
		{
			bAtLeastOnePlayerHolding = true;
			HorizontalBlendSpaceValue += 1.f;
			VerticalBlendSpaceValue = 1.f;
		}
		else
		{
			FVector MovementDir = ParentBlob.PlayerMovementDirection[Game::GetCody()];
			float MoveDot = ParentBlob.ActorForwardVector.DotProduct(MovementDir);
			if (MoveDot < 0.f)
				bCodyTryingToMove = true;
		}

		if (bMayTryingToMove || bCodyTryingToMove)
			VerticalBlendSpaceValue = 0.f;

		if (bAtLeastOnePlayerHolding)
			PlayBlendSpace();
		else
			StopBlendSpace();

		if (bPlayingBlendSpace)
			ParentBlob.SetBlendSpaceValues(HorizontalBlendSpaceValue, VerticalBlendSpaceValue);
	}

	void PlayBlendSpace()
	{
		if (bPlayingBlendSpace)
			return;

		ParentBlob.PlayBlendSpace(ButtonHoldComp.HoldBS);
		bPlayingBlendSpace = true;
		ParentBlob.BlockCapabilities(CapabilityTags::Movement, this);
		ParentBlob.SmoothSetLocationAndRotation(ButtonHoldComp.TargetStandTransform.Location, ButtonHoldComp.TargetStandTransform.Rotator());
	}

	void StopBlendSpace()
	{
		if (!bPlayingBlendSpace)
			return;

		ParentBlob.StopBlendSpace();
		bPlayingBlendSpace = false;
		ParentBlob.UnblockCapabilities(CapabilityTags::Movement, this);
	}
}